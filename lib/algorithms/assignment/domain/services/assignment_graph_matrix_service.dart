import 'dart:ui';

import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';

class AssignmentMatrixInput {
  final List<String> originIds;
  final List<String> destinationIds;
  final List<String> originNames;
  final List<String> destinationNames;
  final List<List<double?>> costs;
  final String originRole;
  final String destinationRole;
  final int defaultOriginColor;
  final int defaultDestinationColor;
  final String costAttributeId;
  final String defaultTypeAlgorithm;
  final String idPrefix;

  const AssignmentMatrixInput({
    required this.originIds,
    required this.destinationIds,
    required this.originNames,
    required this.destinationNames,
    required this.costs,
    required this.originRole,
    required this.destinationRole,
    required this.defaultOriginColor,
    required this.defaultDestinationColor,
    required this.costAttributeId,
    required this.defaultTypeAlgorithm,
    required this.idPrefix,
  });
}

class AssignmentGraphMatrixService {
  static const int maxDimension = 12;

  static String format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  static String? findConnectionCost(
    Grafo graph,
    String originId,
    String destinationId,
    String costAttributeId,
  ) {
    for (final conn in graph.conexiones.values) {
      if (conn.nodoOrigenId == originId &&
          conn.nodoDestinoId == destinationId) {
        for (final attr in conn.atributos) {
          if (attr.atributoId == costAttributeId) {
            return attr.valor;
          }
        }
        if (conn.atributos.isNotEmpty) return conn.atributos.first.valor;
      }
    }
    return null;
  }

  static Offset positionForNewNode(
    Grafo graph,
    String role,
    int index,
    double fallbackX,
    String originRole,
  ) {
    final roleNodes =
        graph.nodos.values.where((node) => node.rol == role).toList()
          ..sort((a, b) => a.y.compareTo(b.y));
    if (roleNodes.isNotEmpty) {
      final averageX =
          roleNodes.map((node) => node.x).reduce((a, b) => a + b) /
          roleNodes.length;
      final nextY =
          roleNodes.last.y +
          110 +
          (index - roleNodes.length).clamp(0, maxDimension) * 110;
      return Offset(averageX, nextY);
    }
    final graphNodes = graph.nodos.values.toList();
    if (graphNodes.isEmpty) {
      return Offset(fallbackX, 120 + index * 110);
    }
    final averageX =
        graphNodes.map((node) => node.x).reduce((a, b) => a + b) /
        graphNodes.length;
    final averageY =
        graphNodes.map((node) => node.y).reduce((a, b) => a + b) /
        graphNodes.length;
    return Offset(
      averageX + (role == originRole ? -180 : 180),
      averageY + index * 110,
    );
  }

  static Grafo buildGraphFromInput(
    Grafo current,
    AssignmentMatrixInput input,
  ) {
    final nodes = <String, Nodo>{};
    final connections = <String, Conexion>{};

    final existingConnections = <String, Conexion>{};
    for (final conn in current.conexiones.values) {
      existingConnections['${conn.nodoOrigenId}|${conn.nodoDestinoId}'] = conn;
    }

    for (var i = 0; i < input.originNames.length; i++) {
      final id = input.originIds[i];
      if (id.contains('_dummy_')) {
        continue;
      }
      final previous = current.nodos[id];
      final pos = previous != null
          ? Offset(previous.x, previous.y)
          : positionForNewNode(
              current,
              input.originRole,
              i,
              120,
              input.originRole,
            );
      nodes[id] = Nodo(
        id: id,
        nombre: input.originNames[i],
        colorValue: previous?.colorValue ?? input.defaultOriginColor,
        x: pos.dx,
        y: pos.dy,
        rol: input.originRole,
      );
    }

    for (var j = 0; j < input.destinationNames.length; j++) {
      final id = input.destinationIds[j];
      if (id.contains('_dummy_')) {
        continue;
      }
      final previous = current.nodos[id];
      final pos = previous != null
          ? Offset(previous.x, previous.y)
          : positionForNewNode(
              current,
              input.destinationRole,
              j,
              480,
              input.originRole,
            );
      nodes[id] = Nodo(
        id: id,
        nombre: input.destinationNames[j],
        colorValue: previous?.colorValue ?? input.defaultDestinationColor,
        x: pos.dx,
        y: pos.dy,
        rol: input.destinationRole,
      );
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < input.originNames.length; i++) {
      for (var j = 0; j < input.destinationNames.length; j++) {
        final cost = input.costs[i][j];
        if (cost == null) continue;

        final originId = input.originIds[i];
        final destinationId = input.destinationIds[j];

        if (originId.contains('_dummy_') || destinationId.contains('_dummy_')) {
          continue;
        }

        final existing = existingConnections['$originId|$destinationId'];
        final id = existing?.id ?? '${input.idPrefix}_conn_${stamp}_${i}_$j';
        final nodeColor =
            nodes[originId]?.colorValue ?? input.defaultOriginColor;
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: originId,
          nodoDestinoId: destinationId,
          colorValue: existing?.colorValue ?? nodeColor,
          direccion: Direccion.unidireccional,
          atributos: [
            AtributoValor(
              atributoId: input.costAttributeId,
              valor: format(cost),
            ),
          ],
          curvatura: existing?.curvatura,
          loopAngle: existing?.loopAngle,
          offsetControlX: existing?.offsetControlX,
          offsetControlY: existing?.offsetControlY,
        );
      }
    }

    return Grafo(
      nodos: nodes,
      conexiones: connections,
      atributosGlobales: current.atributosGlobales,
      tipoAlgoritmo: input.defaultTypeAlgorithm,
    );
  }
}
