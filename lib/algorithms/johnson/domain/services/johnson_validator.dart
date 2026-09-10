import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../models/johnson_models.dart';

class JohnsonValidator {
  static JohnsonValidationResult validate(Grafo grafo) {
    if (grafo.nodos.isEmpty) {
      return const JohnsonValidationResult.invalid(
        'El grafo debe tener al menos un nodo para ejecutar el algoritmo de Johnson.',
      );
    }

    if (grafo.conexiones.isEmpty) {
      return const JohnsonValidationResult.invalid(
        'El grafo debe tener al menos una conexión dirigida.',
      );
    }

    // Check that all connections are strictly unidirectional (directed)
    for (final conn in grafo.conexiones.values) {
      if (conn.direccion != Direccion.unidireccional) {
        return const JohnsonValidationResult.invalid(
          'El algoritmo de Johnson requiere que todas las conexiones sean dirigidas (unidireccionales).',
        );
      }
    }

    // Topological sort / cycle detection (Kahn's algorithm)
    final nodeIds = grafo.nodos.keys.toSet();
    final inDegree = <String, int>{for (final id in nodeIds) id: 0};
    final adjList = <String, List<String>>{for (final id in nodeIds) id: []};

    for (final conn in grafo.conexiones.values) {
      final orig = conn.nodoOrigenId;
      final dest = conn.nodoDestinoId;

      if (nodeIds.contains(orig) && nodeIds.contains(dest)) {
        adjList[orig]?.add(dest);
        inDegree[dest] = (inDegree[dest] ?? 0) + 1;
      }
    }

    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    int visitedCount = 0;
    while (queue.isNotEmpty) {
      final u = queue.removeAt(0);
      visitedCount++;

      for (final v in adjList[u] ?? <String>[]) {
        inDegree[v] = (inDegree[v] ?? 1) - 1;
        if (inDegree[v] == 0) {
          queue.add(v);
        }
      }
    }

    if (visitedCount < nodeIds.length) {
      return const JohnsonValidationResult.invalid(
        'El grafo contiene ciclos. El algoritmo de Johnson requiere un grafo acíclico dirigido (DAG).',
      );
    }

    return const JohnsonValidationResult.valid();
  }
}
