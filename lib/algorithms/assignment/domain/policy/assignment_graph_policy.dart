import 'dart:math';

import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../domain/services/diceware_service.dart';
import '../../../../domain/services/graph_color_generator.dart';
import '../../../../domain/services/graph_geometry.dart';
import '../../../core/graph_algorithm.dart';

/// Role constants for Assignment / Bipartite nodes.
class AssignmentRoles {
  static const String origin = 'origen';
  static const String destination = 'destino';

  static const int originColor = 0xFF00BFA5; // Teal Accent
  static const int destinationColor = 0xFF7C4DFF; // Deep Purple Accent
}

/// Drawing policy and constraints governing the Assignment algorithm.
///
/// Enforces bipartite structure automatically:
/// - Users do not need to manually classify nodes.
/// - Edges can only flow from Origin -> Destination.
/// - A node that already receives incoming edges acts as a Destination and CANNOT emit outgoing connections.
/// - A node that already sends outgoing edges acts as an Origin and CANNOT receive incoming connections.
/// - Self-loops and bidirectional edges are strictly rejected.
class AssignmentGraphPolicy implements GraphAlgorithmPolicy {
  const AssignmentGraphPolicy();

  @override
  PolicyResult canDeleteNode(Grafo grafo, String nodeId) =>
      const PolicyResult.allow();

  @override
  PolicyResult canDeleteConnection(Grafo grafo, String connectionId) =>
      const PolicyResult.allow();

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
    final randomName = generateRandomSingleWord();
    final nodeName = nombre ?? randomName;
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
      rol: params?['rol'] as String?,
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
        'El algoritmo de Asignación no permite auto-conexiones (bucles).',
      );
    }

    if (direccion == Direccion.bidireccional ||
        direccion == Direccion.ninguna) {
      return const PolicyResult.deny(
        'El algoritmo de Asignación solo permite conexiones dirigidas (unidireccionales).',
      );
    }

    final origNode = grafo.nodos[origenId];
    final destNode = grafo.nodos[destinoId];

    if (origNode == null || destNode == null) {
      return const PolicyResult.deny('Nodo no encontrado.');
    }

    // Check duplicate connection
    final existsForward = grafo.conexiones.values.any(
      (c) => c.nodoOrigenId == origenId && c.nodoDestinoId == destinoId,
    );
    if (existsForward) {
      return const PolicyResult.deny(
        'Ya existe una conexión entre estos nodos.',
      );
    }

    // Check reverse connection
    final existsReverse = grafo.conexiones.values.any(
      (c) => c.nodoOrigenId == destinoId && c.nodoDestinoId == origenId,
    );
    if (existsReverse) {
      return const PolicyResult.deny(
        'El algoritmo de Asignación no permite conexiones en sentido contrario.',
      );
    }

    // Explicit role checks (for legacy/specified roles)
    final origRole = origNode.rol;
    final destRole = destNode.rol;

    if (origRole == AssignmentRoles.destination &&
        destRole == AssignmentRoles.origin) {
      return const PolicyResult.deny(
        'En el algoritmo de Asignación solo se permite conectar de Origen hacia Destino (no al revés).',
      );
    }

    if (origRole == AssignmentRoles.destination) {
      return PolicyResult.deny(
        'No se puede conectar desde "${origNode.nombre ?? 'este nodo'}": está configurado como Destino.',
      );
    }

    if (destRole == AssignmentRoles.origin) {
      return PolicyResult.deny(
        'No se puede conectar hacia "${destNode.nombre ?? 'este nodo'}": está configurado como Origen.',
      );
    }

    if (origRole == AssignmentRoles.origin &&
        destRole == AssignmentRoles.origin) {
      return const PolicyResult.deny(
        'En el algoritmo de Asignación no se pueden conectar dos nodos de Origen entre sí.',
      );
    }

    if (origRole == AssignmentRoles.destination &&
        destRole == AssignmentRoles.destination) {
      return const PolicyResult.deny(
        'En el algoritmo de Asignación no se pueden conectar dos nodos de Destino entre sí.',
      );
    }

    // Automatic topology-based detection:
    // 1. If origenId already has incoming connections, it acts as a Destination.
    //    A Destination CANNOT emit outgoing connections.
    final origHasIncoming = grafo.conexiones.values.any(
      (c) => c.nodoDestinoId == origenId,
    );
    if (origHasIncoming) {
      return PolicyResult.deny(
        'No se puede conectar desde "${origNode.nombre ?? 'este nodo'}": ya recibe conexiones y actúa como Destino.',
      );
    }

    // 2. If destinoId already has outgoing connections, it acts as an Origin.
    //    An Origin CANNOT receive incoming connections.
    final destHasOutgoing = grafo.conexiones.values.any(
      (c) => c.nodoOrigenId == destinoId,
    );
    if (destHasOutgoing) {
      return PolicyResult.deny(
        'No se puede conectar hacia "${destNode.nombre ?? 'este nodo'}": ya emite conexiones y actúa como Origen.',
      );
    }

    return const PolicyResult.allow();
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
