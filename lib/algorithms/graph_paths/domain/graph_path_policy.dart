import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/direccion.dart';
import '../../../domain/models/conexion.dart';
import '../../../domain/models/grafo.dart';
import '../../../domain/models/nodo.dart';
import '../../../domain/services/graph_geometry.dart';
import '../../core/graph_algorithm.dart';

class GraphPathPolicy extends GraphAlgorithmPolicy {
  final bool kruskal;
  const GraphPathPolicy({required this.kruskal});

  static const _nodeColors = <int>[
    0xFF6754B2, // violeta
    0xFF008F87, // turquesa
    0xFFD66A32, // naranja
    0xFF3175C5, // azul
    0xFFC24C78, // rosa
    0xFF5F8E36, // verde
    0xFFAD7924, // ocre
    0xFF168AAB, // cian
    0xFF9548A9, // magenta
    0xFF4B62A4, // índigo
    0xFFBD5145, // rojo
    0xFF6D7737, // oliva
  ];

  int _nextNodeColor(Grafo grafo) {
    final used = grafo.nodos.values.map((node) => node.colorValue).toSet();
    final accent = kruskal ? 0xFF8357AD : _nodeColors.first;
    if (!used.contains(accent)) return accent;
    for (final color in _nodeColors) {
      if (kruskal && color == _nodeColors.first) continue;
      if (!used.contains(color)) return color;
    }

    // Extend the palette without recycling an existing color in large graphs.
    for (var index = grafo.nodos.length; ; index++) {
      final hue = (index * 137.508) % 360;
      final saturation = .62 + (index % 3) * .1;
      final value = .78 + (index % 2) * .14;
      final color = HSVColor.fromAHSV(
        1,
        hue,
        saturation,
        value,
      ).toColor().toARGB32();
      if (!used.contains(color)) return color;
    }
  }

  @override
  bool get allowSelfLoops => !kruskal;

  @override
  bool get allowBidirectional => false;

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
    final position = GraphGeometry.clampNodePosition(x, y);
    return Nodo(
      id: 'nodo_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}',
      nombre: nombre ?? 'Nodo ${grafo.nodos.length + 1}',
      colorValue: colorValue ?? _nextNodeColor(grafo),
      x: position.x,
      y: position.y,
    );
  }

  @override
  PolicyResult canCreateConnection(
    Grafo grafo,
    String origenId,
    String destinoId,
    Direccion direccion,
  ) {
    if (!grafo.nodos.containsKey(origenId) ||
        !grafo.nodos.containsKey(destinoId)) {
      return const PolicyResult.deny('Selecciona dos vértices existentes.');
    }
    if (kruskal && origenId == destinoId) {
      return const PolicyResult.deny(
        'Kruskal descarta los bucles porque forman ciclos.',
      );
    }
    if (kruskal && direccion != Direccion.ninguna) {
      return const PolicyResult.deny(
        'Kruskal solo admite aristas no dirigidas.',
      );
    }
    if (direccion == Direccion.bidireccional) {
      return const PolicyResult.deny(
        'Elige una arista dirigida o no dirigida para conservar un peso por arista.',
      );
    }
    if (grafo.conexiones.values.any(
      (edge) =>
          (edge.nodoOrigenId == origenId && edge.nodoDestinoId == destinoId) ||
          (edge.nodoOrigenId == destinoId && edge.nodoDestinoId == origenId),
    )) {
      return const PolicyResult.deny(
        'Ya existe una arista entre estos vértices. Edita su peso o dirección desde el lienzo.',
      );
    }
    return const PolicyResult.allow();
  }

  @override
  List<Direccion> allowedDirections(
    Grafo grafo,
    String origenId,
    String destinoId,
  ) => kruskal
      ? const [Direccion.ninguna]
      : const [Direccion.ninguna, Direccion.unidireccional];

  /// Applies the same construction rules when the shared EditPanel changes an edge.
  PolicyResult canUpdateConnection(
    Grafo grafo,
    Conexion current, {
    required String origenId,
    required String destinoId,
    required Direccion direccion,
    required String weight,
    bool allowNegativeForLongestSimple = false,
  }) {
    if (!grafo.nodos.containsKey(origenId) ||
        !grafo.nodos.containsKey(destinoId)) {
      return const PolicyResult.deny('Selecciona dos vértices existentes.');
    }
    if (kruskal && origenId == destinoId) {
      return const PolicyResult.deny('Kruskal no permite bucles.');
    }
    if (kruskal && direccion != Direccion.ninguna) {
      return const PolicyResult.deny(
        'Kruskal solo admite aristas no dirigidas.',
      );
    }
    if (!kruskal && direccion == Direccion.bidireccional) {
      return const PolicyResult.deny(
        'Dijkstra admite aristas dirigidas o no dirigidas, con un peso por arista.',
      );
    }
    final number = double.tryParse(weight.trim());
    if (number == null ||
        !number.isFinite ||
        (!kruskal && !allowNegativeForLongestSimple && number < 0)) {
      return PolicyResult.deny(
        kruskal || allowNegativeForLongestSimple
            ? 'Introduce un peso numérico finito; este método admite cero y negativos.'
            : 'Dijkstra necesita un peso numérico finito mayor o igual que cero.',
      );
    }
    final changedEndpoints =
        current.nodoOrigenId != origenId || current.nodoDestinoId != destinoId;
    if (changedEndpoints &&
        grafo.conexiones.values.any(
          (edge) =>
              edge.id != current.id &&
              ((edge.nodoOrigenId == origenId &&
                      edge.nodoDestinoId == destinoId) ||
                  (edge.nodoOrigenId == destinoId &&
                      edge.nodoDestinoId == origenId)),
        )) {
      return const PolicyResult.deny(
        'Ya existe una arista entre esos vértices. Elige otra pareja o edita la existente.',
      );
    }
    return const PolicyResult.allow();
  }
}
