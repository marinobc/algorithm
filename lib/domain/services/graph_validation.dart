import '../models/grafo.dart';

class GraphValidation {
  /// Identifies all nodes that are disconnected in the graph.
  /// A node is considered disconnected if it has degree 0 (no connections)
  /// or if the graph has multiple disconnected components (nodes in secondary components).
  static Set<String> findDisconnectedNodes(Grafo grafo) {
    if (grafo.nodos.isEmpty || grafo.nodos.length == 1) {
      return {};
    }

    final allNodeIds = grafo.nodos.keys.toSet();
    final adjacency = <String, Set<String>>{};
    for (final nodeId in allNodeIds) {
      adjacency[nodeId] = {};
    }

    for (final conexion in grafo.conexiones.values) {
      if (adjacency.containsKey(conexion.nodoOrigenId) &&
          adjacency.containsKey(conexion.nodoDestinoId)) {
        adjacency[conexion.nodoOrigenId]!.add(conexion.nodoDestinoId);
        adjacency[conexion.nodoDestinoId]!.add(conexion.nodoOrigenId);
      }
    }

    // Find connected components using BFS/DFS
    final visited = <String>{};
    final components = <Set<String>>[];

    for (final nodeId in allNodeIds) {
      if (!visited.contains(nodeId)) {
        final component = <String>{};
        final queue = <String>[nodeId];
        visited.add(nodeId);

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          component.add(current);

          for (final neighbor in adjacency[current] ?? <String>{}) {
            if (!visited.contains(neighbor)) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }
        components.add(component);
      }
    }

    if (components.length <= 1) {
      return {};
    }

    // Sort components by size descending
    components.sort((a, b) => b.length.compareTo(a.length));

    // The main graph is the largest component. All nodes in secondary components are disconnected.
    final disconnected = <String>{};
    for (int i = 1; i < components.length; i++) {
      disconnected.addAll(components[i]);
    }

    return disconnected;
  }
}
