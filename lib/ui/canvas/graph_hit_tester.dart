import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../domain/services/graph_geometry.dart';

/// Pure domain/spatial hit-testing service for graph nodes and connections.
class GraphHitTester {
  /// Calculates exact Euclidean distance from point [p] to a node's visual capsule boundary.
  /// Distance is <= 0.0 if point is strictly INSIDE the node capsule.
  static double distanceToNodeBoundary(Offset p, Nodo node) {
    final textLength = (node.nombre ?? node.id).length;
    final estimatedTextWidth = textLength * 8.0 + 24.0;
    final halfW = max(node.radius, estimatedTextWidth / 2.0);
    final halfH = node.radius;

    final dx = (p.dx - node.x).abs();
    final dy = (p.dy - node.y).abs();

    if (halfW <= halfH) {
      // Symmetrical circular node
      final distToCenter = sqrt(dx * dx + dy * dy);
      return distToCenter - halfH;
    }

    // Capsule / Pill shape (central rectangle with semicircular ends)
    final straightHalfW = halfW - halfH;
    if (dx <= straightHalfW) {
      // Directly above or below central rectangle
      return dy - halfH;
    } else {
      // Off to the side near semicircular caps
      final capDx = dx - straightHalfW;
      final distToCapCenter = sqrt(capDx * capDx + dy * dy);
      return distToCapCenter - halfH;
    }
  }

  /// Hit-tests nodes on the canvas. Returns touched node or null, sorted by closest proximity.
  static Nodo? hitTestNode(
    Offset worldPos,
    Iterable<Nodo> nodes, {
    double scale = 1.0,
  }) {
    final all = hitTestAllNodes(worldPos, nodes, scale: scale);
    return all.isNotEmpty ? all.first : null;
  }

  /// Returns all nodes touching [worldPos] within a tight border margin, sorted by closest distance to boundary.
  static List<Nodo> hitTestAllNodes(
    Offset worldPos,
    Iterable<Nodo> nodes, {
    double scale = 1.0,
  }) {
    final margin = (scale > 0 && scale.isFinite) ? max(4.0, 8.0 / scale) : 6.0;
    final nodeDistances = <Nodo, double>{};

    for (final node in nodes) {
      final dist = distanceToNodeBoundary(worldPos, node);
      if (dist <= margin) {
        nodeDistances[node] = dist;
      }
    }

    final result = nodeDistances.keys.toList()
      ..sort((a, b) => nodeDistances[a]!.compareTo(nodeDistances[b]!));
    return result;
  }

  /// Evaluates connection line closest to worldPos. Returns touched connection or null.
  static Conexion? hitTestConnection(
    Offset worldPos,
    Grafo grafo,
    double scale,
  ) {
    final all = hitTestAllConnections(worldPos, grafo, scale);
    return all.isNotEmpty ? all.first : null;
  }

  /// Returns all connections touching [worldPos] within tight tolerance, sorted by closest distance to line.
  static List<Conexion> hitTestAllConnections(
    Offset worldPos,
    Grafo grafo,
    double scale,
  ) {
    final connDistances = <Conexion, double>{};
    // Tight stroke tolerance: 8.0 to 14.0 pixels in world coordinates
    final tolerance = (scale > 0 && scale.isFinite)
        ? max(8.0, 14.0 / scale)
        : 10.0;

    final pairCounts = <String, int>{};
    for (final c in grafo.conexiones.values) {
      final key = c.nodoOrigenId.compareTo(c.nodoDestinoId) < 0
          ? '${c.nodoOrigenId}_${c.nodoDestinoId}'
          : '${c.nodoDestinoId}_${c.nodoOrigenId}';
      pairCounts[key] = (pairCounts[key] ?? 0) + 1;
    }

    final pairIndex = <String, int>{};

    final sortedConns = grafo.conexiones.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final conn in sortedConns) {
      final origen = grafo.nodos[conn.nodoOrigenId];
      final destino = grafo.nodos[conn.nodoDestinoId];
      if (origen == null || destino == null) continue;

      final pairKey = conn.nodoOrigenId.compareTo(conn.nodoDestinoId) < 0
          ? '${conn.nodoOrigenId}_${conn.nodoDestinoId}'
          : '${conn.nodoDestinoId}_${conn.nodoOrigenId}';

      final totalInPair = pairCounts[pairKey] ?? 1;
      final currentIdx = pairIndex[pairKey] ?? 0;
      pairIndex[pairKey] = currentIdx + 1;

      final offsetFactor = calculateOffsetFactor(conn, currentIdx, totalInPair);

      final curve = GraphGeometry.calculateBezierCurve(
        origen: origen,
        destino: destino,
        offsetFactor: offsetFactor,
        customCurvatura: conn.curvatura,
        loopAngle: conn.loopAngle,
        offsetControlX: conn.offsetControlX,
        offsetControlY: conn.offsetControlY,
      );

      double connMinDist = double.infinity;
      Offset? prevPt;
      for (double t = 0.0; t <= 1.0; t += 0.02) {
        final px = evalBezier(
          t,
          curve.start.x,
          curve.control1.x,
          curve.control2.x,
          curve.end.x,
        );
        final py = evalBezier(
          t,
          curve.start.y,
          curve.control1.y,
          curve.control2.y,
          curve.end.y,
        );
        final currentPt = Offset(px, py);

        if (prevPt != null) {
          final distToSegment = distanceToSegment(worldPos, prevPt, currentPt);
          if (distToSegment < connMinDist) {
            connMinDist = distToSegment;
          }
        }
        prevPt = currentPt;
      }

      if (connMinDist <= tolerance) {
        connDistances[conn] = connMinDist;
      }
    }

    final result = connDistances.keys.toList()
      ..sort((a, b) => connDistances[a]!.compareTo(connDistances[b]!));

    return result;
  }

  /// Calculates shortest distance from point P to line segment AB.
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    var t =
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    final projection = Offset(
      a.dx + t * (b.dx - a.dx),
      a.dy + t * (b.dy - a.dy),
    );
    return (p - projection).distance;
  }

  /// Evaluates cubic Bezier point value.
  static double evalBezier(
    double t,
    double p0,
    double p1,
    double p2,
    double p3,
  ) {
    final u = 1 - t;
    return u * u * u * p0 +
        3 * u * u * t * p1 +
        3 * u * t * t * p2 +
        t * t * t * p3;
  }

  /// Evaluates cubic Bezier derivative value.
  static double evalBezierDeriv(
    double t,
    double p0,
    double p1,
    double p2,
    double p3,
  ) {
    final u = 1 - t;
    return 3 * u * u * (p1 - p0) +
        6 * u * t * (p2 - p1) +
        3 * t * t * (p3 - p2);
  }

  /// Computes distinct, non-overlapping curvature offset factor for connection lines.
  /// This is the canonical implementation — used by BOTH the renderer (_buildRenderModel)
  /// and the hit-tester (hitTestConnection) so that Bezier curves are identical in both paths.
  static double calculateOffsetFactor(
    Conexion conn,
    int currentIdx,
    int totalInPair,
  ) {
    // A single unidirectional/no-direction line with no pair partner stays centred.
    // A bidirectional pair always has totalInPair == 2, so this guard only fires
    // for truly isolated connections.
    if (totalInPair <= 1 && conn.direccion != Direccion.bidireccional) {
      return 0.0;
    }
    final isCanonicalOrder =
        conn.nodoOrigenId.compareTo(conn.nodoDestinoId) < 0;
    final baseSign = isCanonicalOrder ? 1.0 : -1.0;
    final multiplier = (currentIdx / 2).floor() + 1.0;
    final side = (currentIdx % 2 == 0) ? 1.0 : -1.0;
    return baseSign * multiplier * side;
  }
}
