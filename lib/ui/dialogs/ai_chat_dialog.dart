import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../domain/services/adjacency_matrix_service.dart';
import '../../domain/services/graph_storage_service.dart';
import '../text/user_guide_text.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIChatDialog extends ConsumerStatefulWidget {
  const AIChatDialog({super.key});

  @override
  ConsumerState<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends ConsumerState<AIChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isAnalyzing = false;
  late final String? _apiKey;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GEMINI_API_KEY'] ??
        (const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
            ? const String.fromEnvironment('GEMINI_API_KEY')
            : null);

    _messages.add(
      ChatMessage(
        text: '¡Hola! Soy tu **Asistente Experto en Grafos**.\n\n'
            'Puedes hacerme consultas sobre:\n'
            '• La **matriz de adyacencia** y grados de tu grafo actual.\n'
            '• **Cómo usar la aplicación** y sus funciones.\n'
            '• **Crear o modificar grafos** (ej. *"Crea un grafo con los países de América del Sur y sus fronteras"* o *"Añade un nodo llamado Brasil"*).',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isAnalyzing) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isAnalyzing = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final graph = ref.read(grafoProvider);
      final key = _apiKey?.trim();

      if (key != null && key.isNotEmpty) {
        final systemPrompt = _buildSystemPrompt(graph);
        final chatHistory = _messages.map((m) {
          return m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)]);
        }).toList();

        final response = await _generateWithModelFallback(
          apiKey: key,
          systemPrompt: systemPrompt,
          chatHistory: chatHistory.take(chatHistory.length - 1).toList(),
          userPrompt: text,
        );

        final responseText = response.text ?? 'No se pudo obtener respuesta.';
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(text: responseText, isUser: false));
            _isAnalyzing = false;
          });
          _scrollToBottom();
          _processGraphActions(responseText);
        }
      } else {
        final responseText = _generateLocalFallbackResponse(text, graph);
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(text: responseText, isUser: false));
            _isAnalyzing = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        final isNetworkError = errStr.contains('SocketException') ||
            errStr.contains('Failed host lookup') ||
            errStr.contains('No address associated with hostname') ||
            errStr.contains('network is unreachable');

        final String errorText;
        if (isNetworkError) {
          errorText = '⚠️ Error de conexión a red:\n'
              'No fue posible conectar con los servidores de Gemini AI (Failed host lookup).\n\n'
              'Por favor, verifica tu conexión a Internet e inténtalo de nuevo.';
        } else {
          errorText = '⚠️ Error al comunicarse con Gemini AI: $e\n\n'
              'Asegúrate de que tu `GEMINI_API_KEY` en el archivo `.env` sea válida y tenga acceso a la API.';
        }

        setState(() {
          _messages.add(
            ChatMessage(
              text: errorText,
              isUser: false,
            ),
          );
          _isAnalyzing = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<GenerateContentResponse> _generateWithModelFallback({
    required String apiKey,
    required String systemPrompt,
    required List<Content> chatHistory,
    required String userPrompt,
  }) async {
    final candidateModels = [
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    Object? lastException;

    for (final modelName in candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system(systemPrompt),
        );

        final response = await model.generateContent([
          ...chatHistory,
          Content.text(userPrompt),
        ]);

        return response;
      } catch (e) {
        lastException = e;
        final errLower = e.toString().toLowerCase();
        if (errLower.contains('socketexception') ||
            errLower.contains('failed host lookup') ||
            errLower.contains('no address associated with hostname') ||
            errLower.contains('network is unreachable')) {
          break;
        }
      }
    }

    throw lastException ?? Exception('No se pudo conectar con ningún modelo de Gemini.');
  }

  String _buildGraphContext(Grafo graph) {
    final buffer = StringBuffer();
    buffer.writeln("=== ESTADO DEL GRAFO ACTUAL ===");
    buffer.writeln("Cantidad de Nodos: ${graph.nodos.length}");
    buffer.writeln("Cantidad de Conexiones: ${graph.conexiones.length}");

    if (graph.nodos.isNotEmpty) {
      buffer.writeln("\nNodos:");
      for (final n in graph.nodos.values) {
        buffer.writeln(" - ID: ${n.id}, Nombre: '${n.nombre ?? n.id}', Posición: (${n.x.toStringAsFixed(1)}, ${n.y.toStringAsFixed(1)})");
      }

      buffer.writeln("\nConexiones:");
      for (final c in graph.conexiones.values) {
        final orig = graph.nodos[c.nodoOrigenId]?.nombre ?? c.nodoOrigenId;
        final dest = graph.nodos[c.nodoDestinoId]?.nombre ?? c.nodoDestinoId;
        final attrs = c.atributos.map((a) => "${a.atributoId}: ${a.valor}").join(", ");
        buffer.writeln(" - ID: ${c.id}, Origen: '$orig', Destino: '$dest', Dirección: ${c.direccion.name}, Atributos: [${attrs.isEmpty ? 'Ninguno' : attrs}]");
      }

      final matrixData = AdjacencyMatrixService.calculateMatrix(graph);
      buffer.writeln("\n=== MATRIZ DE ADYACENCIA ===");
      buffer.writeln("Etiquetas de Nodos: ${matrixData.labels.join(', ')}");
      buffer.writeln("Matriz (${matrixData.labels.length}x${matrixData.labels.length}):");
      for (int i = 0; i < matrixData.matrix.length; i++) {
        final rowStr = matrixData.matrix[i].map((cell) => cell.weightedValue).join('\t');
        buffer.writeln(" ${matrixData.labels[i]}\t[ $rowStr ]\t| Suma: ${matrixData.rowSums[i].toStringAsFixed(1)}, Grado: ${matrixData.rowDegrees[i]}");
      }
      buffer.writeln("Grado Máximo Δ(G): ${matrixData.maxDegree}");
      buffer.writeln("Grado Mínimo δ(G): ${matrixData.minDegree}");
      buffer.writeln("Suma Total de Pesos: ${matrixData.totalWeightSum.toStringAsFixed(1)}");
    } else {
      buffer.writeln("El lienzo está actualmente vacío.");
    }
    return buffer.toString();
  }

  String _buildSystemPrompt(Grafo graph) {
    final graphContext = _buildGraphContext(graph);
    final guideContext = UserGuideText.markdownContent;

    return '''
Eres el Asistente Experto en Teoría de Grafos, Modificación de Grafos y Manual de Usuario de esta aplicación.

REGLAS DE RESPUESTA STRICTAS:
1. SOLO debes responder a preguntas o solicitudes relacionadas con:
   a) El grafo y la matriz de adyacencia cargados actualmente (nodos, conexiones, grados, pesos, caminos, propiedades topológicas).
   b) El uso y funcionamiento de la aplicación (explicado en la Guía de Uso adjunta).
   c) Creación, adición, modificación o eliminación de nodos y conexiones en el lienzo.

2. SI EL USUARIO HACE UNA PREGUNTA AJENA O NO RELACIONADA con el grafo, la matriz de adyacencia o el uso de la aplicación (por ejemplo: recetas de cocina, fútbol, chistes, política, programación general), DEBES DECLINAR AMABLEMENTE diciendo:
   "Disculpa, solo puedo responder preguntas sobre el grafo actual, la matriz de adyacencia, cómo usar la app o generar/modificar grafos."

3. ACCIONES DE CREACIÓN Y MODIFICACIÓN DE GRAFOS:
   Cuando el usuario solicite crear, agregar, modificar o eliminar nodos o conexiones:
   - Proporciona una explicación clara en tu respuesta textual.
   - AL FINAL DE TU RESPUESTA, DEBES INCLUIR UN ÚNICO BLOQUE DE CÓDIGO JSON ```json ... ``` con una de las siguientes estructuras de acción (sin alterar los nombres de las claves):

   a) CREAR UN GRAFO COMPLETO (reemplaza el lienzo):
```json
{
  "action": "create_graph",
  "graph_name": "Nombre del Grafo",
  "nodes": ["Nodo A", "Nodo B", "Nodo C"],
  "connections": [
    {"from": "Nodo A", "to": "Nodo B", "directed": true, "weight": 1.0},
    {"from": "Nodo B", "to": "Nodo C", "directed": false, "weight": 2.5}
  ]
}
```

   b) AÑADIR N ELEMENTOS AL GRAFO ACTUAL (sin borrar los existentes):
```json
{
  "action": "add_elements",
  "nodes": ["Nuevo Nodo D"],
  "connections": [
    {"from": "Nodo A", "to": "Nuevo Nodo D", "directed": false, "weight": 3.0}
  ]
}
```

   c) ELIMINAR ELEMENTOS DEL LIENZO:
```json
{
  "action": "remove_elements",
  "nodes": ["Nodo B"]
}
```

   d) ACTUALIZAR ELEMENTOS EXISTENTES (nombres, colores o pesos):
```json
{
  "action": "update_elements",
  "connections": [
    {"from": "Nodo A", "to": "Nodo B", "weight": 10.0, "directed": true}
  ]
}
```

=== INFORMACIÓN DEL GRAFO Y MATRIZ ACTUAL ===
$graphContext

=== GUÍA DE USO DE LA APLICACIÓN ===
$guideContext
''';
  }

  /// Extracts structured JSON objects from LLM text output using a robust brace-matching algorithm.
  List<Map<String, dynamic>> _extractJsonObjects(String text) {
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
              if (decoded is Map<String, dynamic> && decoded.containsKey('action')) {
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

  /// Calculates non-colliding circular positions for new nodes.
  Map<String, Offset> _calculateCircularPositions({
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
        positions[nodeNames[i]] = Offset(cx + radius * cos(angle), cy + radius * sin(angle));
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
        positions[nodeNames[i]] = Offset(cx + radius * cos(angle), cy + radius * sin(angle));
      }
    }

    return positions;
  }

  void _processGraphActions(String responseText) {
    final jsonObjects = _extractJsonObjects(responseText);
    if (jsonObjects.isEmpty) return;

    for (final data in jsonObjects) {
      final action = data['action'] as String?;
      if (action == null) continue;

      switch (action) {
        case 'create_graph':
          _handleCreateGraph(data);
          break;
        case 'add_elements':
        case 'modify_graph':
          _handleAddElements(data);
          break;
        case 'remove_elements':
          _handleRemoveElements(data);
          break;
        case 'update_elements':
          _handleUpdateElements(data);
          break;
      }
    }
  }

  void _handleCreateGraph(Map<String, dynamic> data) {
    try {
      final nodeNames = List<String>.from(data['nodes'] ?? []);
      final rawConns = data['connections'] as List<dynamic>? ?? [];
      if (nodeNames.isEmpty) return;

      final positions = _calculateCircularPositions(
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

        final nodeColor = AppTheme.presetColors[i % AppTheme.presetColors.length].toARGB32();

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
            attrs.add(AtributoValor(atributoId: 'attr_valor', valor: weight.toString()));
          }

          newConns[connId] = Conexion(
            id: connId,
            nodoOrigenId: origId,
            nodoDestinoId: destId,
            direccion: isDirected ? Direccion.unidireccional : Direccion.ninguna,
            atributos: attrs,
            colorValue: newNodes[origId]?.colorValue ?? 0,
          );
        }
      }

      final newGrafo = Grafo(nodos: newNodes, conexiones: newConns);
      ref.read(grafoProvider.notifier).cargarGrafo(newGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      final graphName = data['graph_name'] as String? ?? 'Grafo Generado por IA';
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(
            SavedGraphItem(
              id: 'ai_graph_${DateTime.now().millisecondsSinceEpoch}',
              nombre: graphName,
              fecha: DateTime.now().toIso8601String(),
              nodoCount: newNodes.length,
              conexionCount: newConns.length,
              jsonContent: json.encode(newGrafo.toJson()),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Grafo "$graphName" creado e insertado en el lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _handleAddElements(Map<String, dynamic> data) {
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

      final positions = _calculateCircularPositions(
        nodeNames: brandNewNodeNames,
        existingNodes: existingNodes,
      );

      for (int i = 0; i < brandNewNodeNames.length; i++) {
        final name = brandNewNodeNames[i];
        final pos = positions[name] ?? Offset(i * 80.0, 0);
        final nodeId = 'node_${DateTime.now().millisecondsSinceEpoch}_$i';

        nodeMapByName[name.trim().toLowerCase()] = nodeId;

        final nodeColor = AppTheme.presetColors[(existingNodes.length + i) % AppTheme.presetColors.length].toARGB32();

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
            attrs.add(AtributoValor(atributoId: 'attr_valor', valor: weight.toString()));
          }

          existingConns[connId] = Conexion(
            id: connId,
            nodoOrigenId: origId,
            nodoDestinoId: destId,
            direccion: isDirected ? Direccion.unidireccional : Direccion.ninguna,
            atributos: attrs,
            colorValue: existingNodes[origId]?.colorValue ?? 0,
          );
        }
      }

      final updatedGrafo = Grafo(nodos: existingNodes, conexiones: existingConns);
      ref.read(grafoProvider.notifier).cargarGrafo(updatedGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Nuevos elementos agregados al lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _handleRemoveElements(Map<String, dynamic> data) {
    try {
      final currentGraph = ref.read(grafoProvider);
      final nodesToRemove = List<String>.from(data['nodes'] ?? []);

      final existingNodes = Map<String, Nodo>.from(currentGraph.nodos);
      final existingConns = Map<String, Conexion>.from(currentGraph.conexiones);

      final removedNodeIds = <String>{};
      for (final name in nodesToRemove) {
        final lower = name.trim().toLowerCase();
        existingNodes.removeWhere((id, n) {
          final isMatch = id == name || (n.nombre ?? '').trim().toLowerCase() == lower;
          if (isMatch) removedNodeIds.add(id);
          return isMatch;
        });
      }

      // Remove connections attached to deleted nodes
      existingConns.removeWhere((id, c) {
        return removedNodeIds.contains(c.nodoOrigenId) || removedNodeIds.contains(c.nodoDestinoId);
      });

      final updatedGrafo = Grafo(nodos: existingNodes, conexiones: existingConns);
      ref.read(grafoProvider.notifier).cargarGrafo(updatedGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Elementos eliminados del lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _handleUpdateElements(Map<String, dynamic> data) {
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
          // Find matching connection
          for (final entry in existingConns.entries) {
            final c = entry.value;
            if ((c.nodoOrigenId == origId && c.nodoDestinoId == destId) ||
                (c.nodoOrigenId == destId && c.nodoDestinoId == origId)) {
              final attrs = <AtributoValor>[];
              if (weight != null) {
                attrs.add(AtributoValor(atributoId: 'attr_valor', valor: weight.toString()));
              } else {
                attrs.addAll(c.atributos);
              }

              existingConns[entry.key] = c.copyWith(
                direccion: isDirected != null
                    ? (isDirected ? Direccion.unidireccional : Direccion.ninguna)
                    : c.direccion,
                atributos: attrs,
              );
            }
          }
        }
      }

      final updatedGrafo = Grafo(nodos: existingNodes, conexiones: existingConns);
      ref.read(grafoProvider.notifier).cargarGrafo(updatedGrafo);
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✏️ Conexiones actualizadas en el lienzo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  String _generateLocalFallbackResponse(String userPrompt, Grafo graph) {
    final promptLower = userPrompt.toLowerCase();

    final isGraphQuery = promptLower.contains('matriz') ||
        promptLower.contains('grado') ||
        promptLower.contains('nodo') ||
        promptLower.contains('conexion') ||
        promptLower.contains('arista') ||
        promptLower.contains('resumen') ||
        promptLower.contains('conect') ||
        promptLower.contains('guia') ||
        promptLower.contains('uso') ||
        promptLower.contains('como') ||
        promptLower.contains('ayuda') ||
        promptLower.contains('hola');

    if (!isGraphQuery) {
      return 'Disculpa, solo puedo responder preguntas relacionadas con el grafo y matriz actuales o sobre cómo utilizar esta aplicación de grafos.\n\n'
          '*(Para consultas generativas avanzadas con IA, agrega tu `GEMINI_API_KEY` en el archivo `.env`)*';
    }

    if (promptLower.contains('matriz') || promptLower.contains('adyacencia')) {
      if (graph.nodos.isEmpty) return 'El grafo está vacío. Agrega nodos al lienzo para ver la matriz.';
      final matrixData = AdjacencyMatrixService.calculateMatrix(graph);
      return '### Matriz de Adyacencia Actual\n'
          '• **Dimensiones:** ${matrixData.labels.length}x${matrixData.labels.length}\n'
          '• **Nodos:** ${matrixData.labels.join(", ")}\n'
          '• **Grado Máximo Δ(G):** ${matrixData.maxDegree}\n'
          '• **Grado Mínimo δ(G):** ${matrixData.minDegree}\n'
          '• **Suma Total de Pesos:** ${matrixData.totalWeightSum.toStringAsFixed(1)}';
    }

    if (promptLower.contains('grado') || promptLower.contains('conexion') || promptLower.contains('vecino')) {
      if (graph.nodos.isEmpty) return 'El grafo está vacío.';
      final matrixData = AdjacencyMatrixService.calculateMatrix(graph);
      final summary = <String>[];
      for (int i = 0; i < matrixData.nodes.length; i++) {
        summary.add('• **${matrixData.labels[i]}:** Grado ${matrixData.vertexDegrees[i]} (Suma filas: ${matrixData.rowSums[i].toStringAsFixed(1)})');
      }
      return '### Grados e Incidentes por Nodo\n'
          '${summary.join("\n")}\n\n'
          '• **Δ(G):** ${matrixData.maxDegree} | **δ(G):** ${matrixData.minDegree}';
    }

    if (promptLower.contains('guia') || promptLower.contains('uso') || promptLower.contains('como')) {
      return '### Resumen de la Guía de Uso\n'
          '1. **Crear Nodo:** Toca una zona libre del lienzo.\n'
          '2. **Mover Nodo:** Mueve arrastrando cualquier nodo.\n'
          '3. **Conectar Nodos:** Arrastra desde un nodo de origen hasta el destino.\n'
          '4. **Bucle:** Doble toque en un nodo.\n'
          '5. **Editar/Borrar:** Toca el nodo o arista para abrir el panel de edición inferior.\n'
          '6. **Ver Matriz:** Accesible desde el menú lateral si todos los nodos están conectados.';
    }

    final n = graph.nodos.length;
    final c = graph.conexiones.length;
    return 'Tu grafo actual contiene **$n nodo(s)** y **$c conexión(es)**.\n\n'
        '¿Deseas consultar el **grado de los nodos**, la **matriz de adyacencia** o ver la **guía de uso**?\n\n'
        '*(Nota: Configura tu `GEMINI_API_KEY` en `.env` para desbloquear búsqueda web e inserción automática de grafos por IA)*';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasApiKey = _apiKey != null && _apiKey.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 540,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.auto_awesome, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente IA de Grafos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Análisis de matriz, manual e inserción/edición de grafos',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (!hasApiKey)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.key_rounded, size: 16, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Clave GEMINI_API_KEY no detectada en .env. Modo analizador local activo.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: msg.isUser
                          ? Text(
                              msg.text,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 13,
                              ),
                            )
                          : MarkdownBody(
                              data: msg.text,
                              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                p: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            if (_isAnalyzing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gemini procesando y analizando...',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Consulta la matriz, guía o pide crear/modificar el grafo...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
