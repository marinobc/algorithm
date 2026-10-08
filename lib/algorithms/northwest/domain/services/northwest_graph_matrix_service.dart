import 'dart:ui';

import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../domain/services/graph_color_generator.dart';
import '../../../../domain/services/node_name_deduplicator.dart';
import '../models/northwest_models.dart';
import 'northwest_problem_extractor.dart';

class NorthwestGraphMatrixService {
  static const int maxDimension = 12;

  static String format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  static Offset positionForNewNode(
    Grafo graph,
    String role,
    int index,
    double fallbackX,
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
      averageX + (role == NorthwestRoles.origin ? -180 : 180),
      averageY + index * 110,
    );
  }

  static Grafo buildGraphFromInput(Grafo current, TransportationInput input) {
    final nodes = <String, Nodo>{};
    final connections = <String, Conexion>{};
    final existingConnections = {
      for (final connection in current.conexiones.values)
        '${connection.nodoOrigenId}|${connection.nodoDestinoId}': connection,
    };

    final deduplicatedNames = NodeNameDeduplicator.deduplicateNameList([
      ...input.originNames,
      ...input.destinationNames,
    ]);
    final deduplicatedOrigins = deduplicatedNames.sublist(
      0,
      input.originNames.length,
    );
    final deduplicatedDestinations = deduplicatedNames.sublist(
      input.originNames.length,
    );

    for (var i = 0; i < input.rowCount; i++) {
      final id = input.originIds[i];
      if (id.contains('_dummy_') ||
          input.originNames[i].trim().toLowerCase().startsWith('ficticio')) {
        continue;
      }
      final existing = current.nodos[id];
      final position = positionForNewNode(
        current,
        NorthwestRoles.origin,
        i,
        180,
      );
      nodes[id] = Nodo(
        id: id,
        nombre: deduplicatedOrigins[i],
        colorValue:
            existing?.colorValue ??
            GraphColorGenerator.generateMaximallyDistinctColor(
              Grafo(nodos: nodes),
            ),
        x: existing?.x ?? position.dx,
        y: existing?.y ?? position.dy,
        radius: existing?.radius ?? Nodo.defaultRadius,
        rol: NorthwestRoles.origin,
        cantidad: input.supplies[i],
      );
    }

    for (var j = 0; j < input.columnCount; j++) {
      final id = input.destinationIds[j];
      if (id.contains('_dummy_') ||
          input.destinationNames[j].trim().toLowerCase().startsWith(
            'ficticio',
          )) {
        continue;
      }
      final existing = current.nodos[id];
      final position = positionForNewNode(
        current,
        NorthwestRoles.destination,
        j,
        760,
      );
      nodes[id] = Nodo(
        id: id,
        nombre: deduplicatedDestinations[j],
        colorValue:
            existing?.colorValue ??
            GraphColorGenerator.generateMaximallyDistinctColor(
              Grafo(nodos: nodes),
            ),
        x: existing?.x ?? position.dx,
        y: existing?.y ?? position.dy,
        radius: existing?.radius ?? Nodo.defaultRadius,
        rol: NorthwestRoles.destination,
        cantidad: input.demands[j],
      );
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < input.rowCount; i++) {
      for (var j = 0; j < input.columnCount; j++) {
        final cost = input.costs[i][j];
        if (cost == null) continue; // Blank cell = no connection

        final originId = input.originIds[i];
        final destinationId = input.destinationIds[j];
        if (originId.contains('_dummy_') ||
            destinationId.contains('_dummy_') ||
            input.originNames[i].trim().toLowerCase().startsWith('ficticio') ||
            input.destinationNames[j].trim().toLowerCase().startsWith(
              'ficticio',
            )) {
          continue;
        }

        final existing = existingConnections['$originId|$destinationId'];
        final id = existing?.id ?? 'nw_connection_${stamp}_${i}_$j';
        final nodeColor = nodes[originId]?.colorValue ?? 0xFF2196F3;
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: originId,
          nodoDestinoId: destinationId,
          colorValue: existing?.colorValue ?? nodeColor,
          direccion: Direccion.unidireccional,
          atributos: [
            AtributoValor(atributoId: 'attr_valor', valor: format(cost)),
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
      tipoAlgoritmo: 'northwest',
      metadata: {
        NorthwestMetadata.originOrder: input.originIds.join(','),
        NorthwestMetadata.destinationOrder: input.destinationIds.join(','),
        NorthwestMetadata.objective: input.objective.name,
      },
    );
  }
}
