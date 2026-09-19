import 'dart:math';

import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../domain/services/graph_color_generator.dart';
import '../../../../domain/services/graph_geometry.dart';
import '../../../core/graph_algorithm.dart';
import '../services/northwest_problem_extractor.dart';

class NorthwestGraphPolicy implements GraphAlgorithmPolicy {
  const NorthwestGraphPolicy();

  @override
  PolicyResult canCreateNode(
    Grafo grafo,
    double x,
    double y, {
    Map<String, dynamic>? params,
  }) => const PolicyResult.allow();

  @override
  Nodo prepareNewNode(
    Grafo grafo,
    double x,
    double y, {
    String? nombre,
    int? colorValue,
    Map<String, dynamic>? params,
  }) {
    final role = params?['role'] as String? ?? NorthwestRoles.origin;
    final sameRoleCount = grafo.nodos.values
        .where((node) => node.rol == role)
        .length;
    final isOrigin = role == NorthwestRoles.origin;
    final defaultName = isOrigin
        ? _originName(sameRoleCount)
        : 'D${sameRoleCount + 1}';
    final clamped = GraphGeometry.clampNodePosition(x, y);
    return Nodo(
      id: 'nw_node_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000)}',
      nombre: nombre ?? defaultName,
      colorValue:
          colorValue ??
          GraphColorGenerator.generateMaximallyDistinctColor(grafo),
      x: clamped.x,
      y: clamped.y,
      rol: role,
      cantidad: 0,
    );
  }

  @override
  PolicyResult canCreateConnection(
    Grafo grafo,
    String origenId,
    String destinoId,
    Direccion direccion,
  ) {
    final origin = grafo.nodos[origenId];
    final destination = grafo.nodos[destinoId];
    if (origin == null || destination == null) {
      return const PolicyResult.deny('No se encontraron ambos nodos.');
    }
    if (origin.rol != NorthwestRoles.origin ||
        destination.rol != NorthwestRoles.destination) {
      return const PolicyResult.deny(
        'Solo puedes conectar un origen con un destino, en ese orden.',
      );
    }
    final duplicate = grafo.conexiones.values.any(
      (connection) =>
          connection.nodoOrigenId == origenId &&
          connection.nodoDestinoId == destinoId,
    );
    if (duplicate) {
      return const PolicyResult.deny(
        'Esta celda de transporte ya tiene una conexion.',
      );
    }
    return const PolicyResult.allow();
  }

  @override
  List<Direccion> allowedDirections(
    Grafo grafo,
    String origenId,
    String destinoId,
  ) => const [Direccion.unidireccional];

  @override
  PolicyResult canDeleteNode(Grafo grafo, String nodeId) =>
      const PolicyResult.allow();

  @override
  PolicyResult canDeleteConnection(Grafo grafo, String connectionId) =>
      const PolicyResult.allow();

  @override
  bool get allowSelfLoops => false;

  @override
  bool get allowBidirectional => false;

  static String _originName(int index) =>
      index < 26 ? String.fromCharCode(65 + index) : 'O${index + 1}';
}
