import '../../../domain/models/direccion.dart';
import '../../../domain/models/grafo.dart';

/// A suggestion, never a claim that these are mathematically required endpoints.
class GraphPathEndpoints {
  final String? sourceId;
  final String? targetId;
  final bool inferredFromTopology;

  const GraphPathEndpoints({
    required this.sourceId,
    required this.targetId,
    required this.inferredFromTopology,
  });

  static GraphPathEndpoints suggest(Grafo graph) {
    final ids = graph.nodos.keys.toList();
    if (ids.isEmpty) {
      return const GraphPathEndpoints(
        sourceId: null,
        targetId: null,
        inferredFromTopology: false,
      );
    }

    final edges = graph.conexiones.values.toList();
    if (edges.isNotEmpty &&
        edges.every((edge) => edge.direccion == Direccion.unidireccional)) {
      final incoming = {for (final id in ids) id: 0};
      final outgoing = {for (final id in ids) id: 0};
      for (final edge in edges) {
        if (incoming.containsKey(edge.nodoDestinoId) &&
            outgoing.containsKey(edge.nodoOrigenId)) {
          incoming[edge.nodoDestinoId] = incoming[edge.nodoDestinoId]! + 1;
          outgoing[edge.nodoOrigenId] = outgoing[edge.nodoOrigenId]! + 1;
        }
      }
      final sources = ids.where((id) => incoming[id] == 0).toList();
      final targets = ids.where((id) => outgoing[id] == 0).toList();
      if (sources.length == 1 &&
          targets.length == 1 &&
          (sources.single != targets.single || ids.length == 1)) {
        return GraphPathEndpoints(
          sourceId: sources.single,
          targetId: targets.single,
          inferredFromTopology: true,
        );
      }
    }

    return GraphPathEndpoints(
      sourceId: ids.first,
      targetId: ids.last,
      inferredFromTopology: false,
    );
  }
}
