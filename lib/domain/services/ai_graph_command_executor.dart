import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../domain/services/graph_storage_service.dart';
import '../../ui/theme/app_theme.dart';

/// Helper service responsible for extracting structured graph modification
/// JSON actions from LLM responses and executing them on the active graph state.
class AIGraphCommandExecutor {
  /// Extracts structured JSON objects from LLM text output using code blocks
  /// and balance-based scanning fallbacks.
  static List<Map<String, dynamic>> extractJsonObjects(String text) {
    final results = <Map<String, dynamic>>[];

    // 1. Try code block parsing first
    final codeBlockRegExp = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    for (final match in codeBlockRegExp.allMatches(text)) {
      final codeContent = match.group(1)?.trim();
      if (codeContent != null && codeContent.startsWith('{')) {
        try {
          final decoded = json.decode(codeContent);
          if (decoded is Map<String, dynamic>) {
            results.add(decoded);
          }
        } catch (_) {}
      }
    }

    if (results.isNotEmpty) return results;

    // 2. Fallback: balance-based JSON scanner
    int depth = 0;
    int startIdx = -1;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '{') {
        if (depth == 0) startIdx = i;
        depth++;
      } else if (char == '}') {
        if (depth > 0) {
          depth--;
          if (depth == 0 && startIdx != -1) {
            final candidate = text.substring(startIdx, i + 1).trim();
            try {
              final decoded = json.decode(candidate);
              if (decoded is Map<String, dynamic> &&
                  decoded.containsKey('action')) {
                results.add(decoded);
              }
            } catch (_) {}
            startIdx = -1;
          }
        }
      }
    }

    return results;
  }

  /// Calculates non-colliding circular positions for newly inserted nodes.
  static Map<String, Offset> calculateCircularPositions({
    required List<String> nodeNames,
    required Map<String, Nodo> existingNodes,
  }) {
    final positions = <String, Offset>{};
    final n = nodeNames.length;
    if (n == 0) return positions;

    if (existingNodes.isEmpty) {
      const cx = 0.0;
      const cy = 0.0;
      final radius = max(220.0, n * 55.0);

      for (int i = 0; i < n; i++) {
        final angle = i * (2 * pi / n);
        positions[nodeNames[i]] = Offset(
          cx + radius * cos(angle),
          cy + radius * sin(angle),
        );
      }
    } else {
      double minX = double.infinity, maxX = -double.infinity;
      double minY = double.infinity, maxY = -double.infinity;

      for (final node in existingNodes.values) {
        if (node.x < minX) minX = node.x;
        if (node.x > maxX) maxX = node.x;
        if (node.y < minY) minY = node.y;
        if (node.y > maxY) maxY = node.y;
      }

      final cx = (minX + maxX) / 2.0;
      final cy = (minY + maxY) / 2.0;

      double maxExistingDist = 0.0;
      for (final node in existingNodes.values) {
        final dist = sqrt(pow(node.x - cx, 2) + pow(node.y - cy, 2));
        if (dist > maxExistingDist) maxExistingDist = dist;
      }

      final radius = max(maxExistingDist + 220.0, n * 55.0);

      for (int i = 0; i < n; i++) {
        final angle = i * (2 * pi / n);
        positions[nodeNames[i]] = Offset(
          cx + radius * cos(angle),
          cy + radius * sin(angle),
        );
      }
    }

    return positions;
  }

  /// Parses action JSONs and applies mutations to the graph.
  static void processGraphActions({
    required String responseText,
    required WidgetRef ref,
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    final jsonObjects = extractJsonObjects(responseText);
    if (jsonObjects.isEmpty) return;

    for (final data in jsonObjects) {
      final action = data['action'] as String?;
      if (action == null) continue;

      switch (action) {
        case 'create_graph':
          _handleCreateGraph(data, ref, context, isMounted);
          break;
        case 'add_elements':
        case 'modify_graph':
          _handleAddElements(data, ref, context, isMounted);
          break;
        case 'remove_elements':
          _handleRemoveElements(data, ref, context, isMounted);
          break;
        case 'update_elements':
          _handleUpdateElements(data, ref, context, isMounted);
          break;
      }
    }
  }

  static void _handleCreateGraph(
    Map<String, dynamic> data,
    WidgetRef ref,
    BuildContext context,
    bool Function() isMounted,
  ) {
    try {
      final nodeNames = List<String>.from(data['nodes'] ?? []);
      final rawConns = data['connections'] as List<dynamic>? ?? [];
      if (nodeNames.isEmpty) return;

      final positions = calculateCircularPositions(
        nodeNames: nodeNames,
        existingNodes: const {},
      );

      final newNodes = <String, Nodo>{};
      final newConns = <String, Conexion>{};
      final nodeMapByName = <String, String>{};

      for (int i = 0; i < nodeNames.length; i++) {
        final name = nodeNames[i];
        final pos = positions[name] ?? Offset(i * 80.0, 0);
        final nodeId = 'node_${DateTime.now().millisecondsSinceEpoch}_$i';

        nodeMapByName[name.trim().toLowerCase()] = nodeId;

        final nodeColor = AppTheme
            .presetColors[i % AppTheme.presetColors.length]
            .toARGB32();

        newNodes[nodeId] = Nodo(
          id: nodeId,
          nombre: name,
          colorValue: nodeColor,
          x: pos.dx,
          y: pos.dy,
        );
      }

      for (int i = 0; i < rawConns.length; i++) {
        final connMap = rawConns[i] as Map<String, dynamic>;
        final fromName = (connMap['from'] as String?)?.trim().toLowerCase();
        final toName = (connMap['to'] as String?)?.trim().toLowerCase();
        final isDirected = (connMap['directed'] as bool?) ?? false;
        final weight = (connMap['weight'] as num?)?.toDouble();

        final origId = nodeMapByName[fromName];
        final destId = nodeMapByName[toName];

        if (origId != null && destId != null) {
          final connId = 'conn_${DateTime.now().millisecondsSinceEpoch}_$i';
          final attrs = <AtributoValor>[];
          if (weight != null) {
            attrs.add(
              AtributoValor(atributoId: 'attr_valor', valor: weight.toString()),
            );
          }

          newConns[connId] = Conexion(
            id: connId,
            nodoOrigenId: origId,
            nodoDestinoId: destId,
            direccion: isDirected
                ? Direccion.unidireccional
                : Direccion.ninguna,
            atributos: attrs,
            colorValue: newNodes[origId]?.colorValue ?? 0,
          );
        }
      }

      final newGrafo = Grafo(nodos: newNodes, conexiones: newConns);
      ref.read(grafoProvider.notifier).cargarGrafo(newGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      final graphName =
          data['graph_name'] as String? ?? 'Grafo Generado por IA';
      ref
          .read(loadedGraphItemProvider.notifier)
          .setLoadedItem(
            SavedGraphItem(
              id: 'ai_graph_${DateTime.now().millisecondsSinceEpoch}',
              nombre: graphName,
              fecha: DateTime.now().toIso8601String(),
              nodoCount: newNodes.length,
              conexionCount: newConns.length,
              jsonContent: json.encode(newGrafo.toJson()),
            ),
          );

      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Grafo "$graphName" creado e insertado en el lienzo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  static void _handleAddElements(
    Map<String, dynamic> data,
    WidgetRef ref,
    BuildContext context,
    bool Function() isMounted,
  ) {
    try {
      final currentGraph = ref.read(grafoProvider);
      final rawNewNodeNames = List<String>.from(data['nodes'] ?? []);
      final rawConns = data['connections'] as List<dynamic>? ?? [];

      final existingNodes = Map<String, Nodo>.from(currentGraph.nodos);
      final existingConns = Map<String, Conexion>.from(currentGraph.conexiones);

      final nodeMapByName = <String, String>{};
      for (final n in existingNodes.values) {
        nodeMapByName[(n.nombre ?? n.id).trim().toLowerCase()] = n.id;
      }

      final brandNewNodeNames = <String>[];
      for (final name in rawNewNodeNames) {
        if (!nodeMapByName.containsKey(name.trim().toLowerCase())) {
          brandNewNodeNames.add(name);
        }
      }

      final positions = calculateCircularPositions(
        nodeNames: brandNewNodeNames,
        existingNodes: existingNodes,
      );

      for (int i = 0; i < brandNewNodeNames.length; i++) {
        final name = brandNewNodeNames[i];
        final pos = positions[name] ?? Offset(i * 80.0, 0);
        final nodeId = 'node_${DateTime.now().millisecondsSinceEpoch}_$i';

        nodeMapByName[name.trim().toLowerCase()] = nodeId;

        final nodeColor = AppTheme
            .presetColors[(existingNodes.length + i) %
                AppTheme.presetColors.length]
            .toARGB32();

        existingNodes[nodeId] = Nodo(
          id: nodeId,
          nombre: name,
          colorValue: nodeColor,
          x: pos.dx,
          y: pos.dy,
        );
      }

      for (int i = 0; i < rawConns.length; i++) {
        final connMap = rawConns[i] as Map<String, dynamic>;
        final fromName = (connMap['from'] as String?)?.trim().toLowerCase();
        final toName = (connMap['to'] as String?)?.trim().toLowerCase();
        final isDirected = (connMap['directed'] as bool?) ?? false;
        final weight = (connMap['weight'] as num?)?.toDouble();

        final origId = nodeMapByName[fromName];
        final destId = nodeMapByName[toName];

        if (origId != null && destId != null) {
          final connId = 'conn_${DateTime.now().millisecondsSinceEpoch}_$i';
          final attrs = <AtributoValor>[];
          if (weight != null) {
            attrs.add(
              AtributoValor(atributoId: 'attr_valor', valor: weight.toString()),
            );
          }

          existingConns[connId] = Conexion(
            id: connId,
            nodoOrigenId: origId,
            nodoDestinoId: destId,
            direccion: isDirected
                ? Direccion.unidireccional
                : Direccion.ninguna,
            atributos: attrs,
            colorValue: existingNodes[origId]?.colorValue ?? 0,
          );
        }
      }

      final updatedGrafo = Grafo(
        nodos: existingNodes,
        conexiones: existingConns,
      );
      ref.read(grafoProvider.notifier).cargarGrafo(updatedGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Nuevos elementos agregados al lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  static void _handleRemoveElements(
    Map<String, dynamic> data,
    WidgetRef ref,
    BuildContext context,
    bool Function() isMounted,
  ) {
    try {
      final currentGraph = ref.read(grafoProvider);
      final nodesToRemove = List<String>.from(data['nodes'] ?? []);

      final existingNodes = Map<String, Nodo>.from(currentGraph.nodos);
      final existingConns = Map<String, Conexion>.from(currentGraph.conexiones);

      final removedNodeIds = <String>{};
      for (final name in nodesToRemove) {
        final lower = name.trim().toLowerCase();
        existingNodes.removeWhere((id, n) {
          final isMatch =
              id == name || (n.nombre ?? '').trim().toLowerCase() == lower;
          if (isMatch) removedNodeIds.add(id);
          return isMatch;
        });
      }

      existingConns.removeWhere((id, c) {
        return removedNodeIds.contains(c.nodoOrigenId) ||
            removedNodeIds.contains(c.nodoDestinoId);
      });

      final updatedGrafo = Grafo(
        nodos: existingNodes,
        conexiones: existingConns,
      );
      ref.read(grafoProvider.notifier).cargarGrafo(updatedGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Elementos eliminados del lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  static void _handleUpdateElements(
    Map<String, dynamic> data,
    WidgetRef ref,
    BuildContext context,
    bool Function() isMounted,
  ) {
    try {
      final currentGraph = ref.read(grafoProvider);
      final rawConns = data['connections'] as List<dynamic>? ?? [];

      final existingNodes = Map<String, Nodo>.from(currentGraph.nodos);
      final existingConns = Map<String, Conexion>.from(currentGraph.conexiones);

      final nodeMapByName = <String, String>{};
      for (final n in existingNodes.values) {
        nodeMapByName[(n.nombre ?? n.id).trim().toLowerCase()] = n.id;
      }

      for (final rawC in rawConns) {
        final connMap = rawC as Map<String, dynamic>;
        final fromName = (connMap['from'] as String?)?.trim().toLowerCase();
        final toName = (connMap['to'] as String?)?.trim().toLowerCase();
        final weight = (connMap['weight'] as num?)?.toDouble();
        final isDirected = connMap['directed'] as bool?;

        final origId = nodeMapByName[fromName];
        final destId = nodeMapByName[toName];

        if (origId != null && destId != null) {
          for (final entry in existingConns.entries) {
            final c = entry.value;
            if ((c.nodoOrigenId == origId && c.nodoDestinoId == destId) ||
                (c.nodoOrigenId == destId && c.nodoDestinoId == origId)) {
              final attrs = <AtributoValor>[];
              if (weight != null) {
                attrs.add(
                  AtributoValor(
                    atributoId: 'attr_valor',
                    valor: weight.toString(),
                  ),
                );
              } else {
                attrs.addAll(c.atributos);
              }

              existingConns[entry.key] = c.copyWith(
                direccion: isDirected != null
                    ? (isDirected
                          ? Direccion.unidireccional
                          : Direccion.ninguna)
                    : c.direccion,
                atributos: attrs,
              );
            }
          }
        }
      }

      final updatedGrafo = Grafo(
        nodos: existingNodes,
        conexiones: existingConns,
      );
      ref.read(grafoProvider.notifier).cargarGrafo(updatedGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✏️ Conexiones actualizadas en el lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }
}
