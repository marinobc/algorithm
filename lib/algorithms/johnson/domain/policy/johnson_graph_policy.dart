import 'dart:math';

import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../domain/services/graph_color_generator.dart';
import '../../../../domain/services/graph_geometry.dart';
import '../../../core/graph_algorithm.dart';

/// Drawing policy and constraints governing the Johnson algorithm (CPM / DAG).
///
/// Enforces directed acyclic graph (DAG) structure:
/// - All connections must be strictly [Direccion.unidireccional].
/// - Self-loops and bidirectional connections are strictly forbidden.
/// - Adding a backward edge that introduces a directed cycle is detected in real-time
///   via reachability check and prevented immediately with descriptive feedback.
class JohnsonGraphPolicy implements GraphAlgorithmPolicy {
  static const int defaultNodeColor = 0xFF00BFA5; // Teal Cyan for Johnson/CPM

  const JohnsonGraphPolicy();

  @override
  PolicyResult canCreateNode(
    Grafo grafo,
    double x,
    double y, {
    Map<String, dynamic>? params,
  }) {
    return const PolicyResult.allow();
  }

  @override
  Nodo prepareNewNode(
    Grafo grafo,
    double x,
    double y, {
    String? nombre,
    int? colorValue,
    Map<String, dynamic>? params,
  }) {
    final nextNumber = grafo.nodos.length + 1;
    final nodeName = nombre ?? 'Actividad $nextNumber';
    final nodeColor =
        colorValue ?? GraphColorGenerator.generateMaximallyDistinctColor(grafo);

    final clamped = GraphGeometry.clampNodePosition(x, y);
    final nodeId =
        'nodo_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000)}';

    return Nodo(
      id: nodeId,
      nombre: nodeName,
      colorValue: nodeColor,
      x: clamped.x,
      y: clamped.y,
    );
  }

  @override
  PolicyResult canCreateConnection(
    Grafo grafo,
    String origenId,
    String destinoId,
    Direccion direccion,
  ) {
    if (origenId == destinoId) {
      return const PolicyResult.deny(
        'El algoritmo de Johnson no permite auto-conexiones (bucles).',
      );
    }

    if (direccion == Direccion.bidireccional) {
      return const PolicyResult.deny(
        'El algoritmo de Johnson requiere conexiones estrictamente unidireccionales (no bidireccionales).',
      );
    }

    if (direccion == Direccion.ninguna) {
      return const PolicyResult.deny(
        'El algoritmo de Johnson requiere que las conexiones tengan dirección (unidireccionales).',
      );
    }

    final origNode = grafo.nodos[origenId];
    final destNode = grafo.nodos[destinoId];

    final origName = origNode?.nombre ?? origenId;
    final destName = destNode?.nombre ?? destinoId;

    // Check if forward connection already exists
    final existsForward = grafo.conexiones.values.any(
      (c) => c.nodoOrigenId == origenId && c.nodoDestinoId == destinoId,
    );
    if (existsForward) {
      return PolicyResult.deny(
        'Ya existe una conexión directa de "$origName" a "$destName".',
      );
    }

    // Check if reverse connection already exists
    final existsReverse = grafo.conexiones.values.any(
      (c) => c.nodoOrigenId == destinoId && c.nodoDestinoId == origenId,
    );
    if (existsReverse) {
      return PolicyResult.deny(
        'No se puede conectar de "$origName" a "$destName": ya existe una conexión en sentido contrario y crearía un ciclo bidireccional.',
      );
    }

    // Real-time Cycle Detection:
    // Adding U -> V creates a directed cycle if and only if there is already a path from V -> U.
    if (_hasPath(grafo, startId: destinoId, targetId: origenId)) {
      return PolicyResult.deny(
        'No se puede conectar de "$origName" a "$destName": formaría un ciclo hacia atrás. El algoritmo de Johnson requiere un grafo acíclico dirigido (DAG).',
      );
    }

    return const PolicyResult.allow();
  }

  /// Evaluates whether a directed path exists from [startId] to [targetId].
  bool _hasPath(
    Grafo grafo, {
    required String startId,
    required String targetId,
  }) {
    final visited = <String>{startId};
    final queue = <String>[startId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == targetId) return true;

      for (final conn in grafo.conexiones.values) {
        if (conn.direccion == Direccion.unidireccional &&
            conn.nodoOrigenId == current) {
          final nextId = conn.nodoDestinoId;
          if (!visited.contains(nextId)) {
            visited.add(nextId);
            queue.add(nextId);
          }
        }
      }
    }

    return false;
  }

  @override
  List<Direccion> allowedDirections(
    Grafo grafo,
    String origenId,
    String destinoId,
  ) {
    return const [Direccion.unidireccional];
  }

  @override
  bool get allowSelfLoops => false;

  @override
  bool get allowBidirectional => false;
}
