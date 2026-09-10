import 'dart:math';

import 'package:flutter/material.dart';

import '../models/nodo.dart';

class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  double distanceTo(Point2D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }
}

class ConnectionPoint {
  final Point2D point;
  final double angleRadians;
  final int index; // 0 to 11

  const ConnectionPoint({
    required this.point,
    required this.angleRadians,
    required this.index,
  });
}

class BezierCurve2D {
  final Point2D start;
  final Point2D control1;
  final Point2D control2;
  final Point2D end;

  const BezierCurve2D({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });
}

class GraphGeometry {
  /// Calculates exact node width accounting for text length and padding.
  static double getNodeWidth(Nodo nodo) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: nodo.nombre ?? nodo.id,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final minDiameter = nodo.diameter;
    final textWidth = textPainter.width + 24.0;
    return max(minDiameter, textWidth);
  }

  /// Calculate 12 connection points around node perimeter.
  static List<ConnectionPoint> get12ConnectionPoints(Nodo nodo) {
    final points = <ConnectionPoint>[];
    for (int i = 0; i < 12; i++) {
      final angle = i * (pi / 6.0); // 30 degrees = pi / 6
      final pt = getPerimeterPoint(nodo, angle);
      points.add(ConnectionPoint(point: pt, angleRadians: angle, index: i));
    }
    return points;
  }

  /// Select the exact perimeter connection point toward the target position (tx, ty) at any angle.
  static ConnectionPoint selectBestConnectionPoint(
    Nodo nodo,
    double tx,
    double ty, {
    double? overrideWidth,
  }) {
    final dx = tx - nodo.x;
    final dy = ty - nodo.y;
    var targetAngle = atan2(dy, dx);
    if (targetAngle < 0) {
      targetAngle += 2 * pi;
    }

    final point = getPerimeterPoint(
      nodo,
      targetAngle,
      overrideWidth: overrideWidth,
    );
    return ConnectionPoint(point: point, angleRadians: targetAngle, index: -1);
  }

  /// Calculates exact perimeter anchor point at any angle [angleRadians] for a node
  /// (accounting for capsule/pill width when text makes the node larger).
  static Point2D getPerimeterPoint(
    Nodo nodo,
    double angleRadians, {
    double? overrideWidth,
  }) {
    final halfH = nodo.radius;
    final nodeWidth = overrideWidth ?? getNodeWidth(nodo);
    final halfW = max(halfH, nodeWidth / 2.0);

    if (halfW <= halfH) {
      return Point2D(
        nodo.x + halfH * cos(angleRadians),
        nodo.y + halfH * sin(angleRadians),
      );
    }

    final r = halfH;
    final dx = halfW - halfH;
    final cosA = cos(angleRadians);
    final sinA = sin(angleRadians);

    // Check intersection with flat top or bottom edge of the capsule
    if (sinA != 0) {
      final tFlat = r / sinA.abs();
      final xFlat = tFlat * cosA;
      if (xFlat.abs() <= dx) {
        return Point2D(nodo.x + xFlat, nodo.y + (sinA > 0 ? r : -r));
      }
    }

    // Intersection with left or right semicircle cap of the capsule
    final cx = cosA > 0 ? dx : -dx;
    final sinSq = sinA * sinA;
    final radTerm = r * r - cx * cx * sinSq;
    final tCap = cosA * cx + sqrt(max(0.0, radTerm));
    return Point2D(nodo.x + tCap * cosA, nodo.y + tCap * sinA);
  }

  /// Calculate Bezier curve between source and target node connection points.
  /// If [origen.id == destino.id], creates a self-loop Bezier curve oriented at [loopAngle] (or top by default).
  /// If [offsetControlX] and [offsetControlY] are provided, uses them to position 2D curve peak anywhere on the canvas.
  /// Otherwise, uses [customCurvatura] or [offsetFactor] to scale curve undulation.
  static BezierCurve2D calculateBezierCurve({
    required Nodo origen,
    required Nodo destino,
    double offsetFactor = 0.0,
    double? customCurvatura,
    double? loopAngle,
    double? offsetControlX,
    double? offsetControlY,
  }) {
    final effectiveFactor =
        customCurvatura ?? (offsetFactor != 0.0 ? offsetFactor * 0.25 : 0.04);

    if (origen.id == destino.id) {
      // 360-Degree Circular Self-Loop connection oriented around loopAngle
      final centerAngle = loopAngle ?? (-pi / 2.0); // Top (-90 deg) by default
      final nodeWidth = getNodeWidth(origen);
      final halfW = max(origen.radius, nodeWidth / 2.0);

      // Smooth circular loop radius calculation: grows cleanly with curvatura
      final loopRadius =
          halfW *
          (1.1 +
              (effectiveFactor < 0 ? 0.0 : effectiveFactor.clamp(0.0, 6.0)) *
                  0.6);

      // Symmetrical anchor points on node perimeter
      final startAngle = centerAngle + (pi / 4.5); // +40 deg
      final endAngle = centerAngle - (pi / 4.5); // -40 deg

      final start = getPerimeterPoint(origen, startAngle);
      final end = getPerimeterPoint(origen, endAngle);

      // Circular cubic Bezier control points that form a smooth round loop
      final c1 = Point2D(
        origen.x + (halfW + loopRadius * 1.55) * cos(centerAngle + 0.52),
        origen.y + (halfW + loopRadius * 1.55) * sin(centerAngle + 0.52),
      );
      final c2 = Point2D(
        origen.x + (halfW + loopRadius * 1.55) * cos(centerAngle - 0.52),
        origen.y + (halfW + loopRadius * 1.55) * sin(centerAngle - 0.52),
      );

      return BezierCurve2D(start: start, control1: c1, control2: c2, end: end);
    }

    final rawDx = destino.x - origen.x;
    final rawDy = destino.y - origen.y;
    final rawDist = sqrt(rawDx * rawDx + rawDy * rawDy);

    // Normal vector perpendicular to line
    final rNx = rawDist == 0 ? 0.0 : -rawDy / rawDist;
    final rNy = rawDist == 0 ? 0.0 : rawDx / rawDist;

    final midX = (origen.x + destino.x) / 2.0;
    final midY = (origen.y + destino.y) / 2.0;

    final double peakTargetX;
    final double peakTargetY;
    final double effOffsetX;
    final double effOffsetY;

    // Sub-linear logarithmic handle magnitude scaling preventing oversized curves on long distances
    final adaptiveMagnitude = min(
      rawDist * 0.40,
      36.0 + 75.0 * log(1.0 + rawDist / 120.0),
    );

    if (offsetControlX != null && offsetControlY != null) {
      // Smooth exponential dampening so extreme 2D drag distances maintain proportional curve elegance
      final dampFactor = rawDist == 0
          ? 1.0
          : min(1.0, 1.2 * (1.0 - exp(-rawDist / 350.0)));
      effOffsetX = offsetControlX * dampFactor;
      effOffsetY = offsetControlY * dampFactor;
      peakTargetX = midX + effOffsetX;
      peakTargetY = midY + effOffsetY;
    } else {
      effOffsetX = rNx * (adaptiveMagnitude * effectiveFactor);
      effOffsetY = rNy * (adaptiveMagnitude * effectiveFactor);
      peakTargetX = midX + effOffsetX;
      peakTargetY = midY + effOffsetY;
    }

    final cpOrigen = selectBestConnectionPoint(
      origen,
      peakTargetX,
      peakTargetY,
    );
    final cpDestino = selectBestConnectionPoint(
      destino,
      peakTargetX,
      peakTargetY,
    );

    final start = cpOrigen.point;
    final end = cpDestino.point;

    final dx = end.x - start.x;
    final dy = end.y - start.y;

    final c1x = start.x + (dx * 0.30) + effOffsetX;
    final c1y = start.y + (dy * 0.30) + effOffsetY;

    final c2x = start.x + (dx * 0.70) + effOffsetX;
    final c2y = start.y + (dy * 0.70) + effOffsetY;

    return BezierCurve2D(
      start: start,
      control1: Point2D(c1x, c1y),
      control2: Point2D(c2x, c2y),
      end: end,
    );
  }

  static const double worldGridExtent = 2400.0; // [-2400.0, 2400.0]
  static const double maxNodeCoord =
      2376.0; // 2400.0 - 24.0 radius (node stays inside 100x100 grid)

  /// Clamps node position so the entire node body stays strictly inside world grid [-2400, 2400].
  static Point2D clampNodePosition(double x, double y) {
    return Point2D(
      x.clamp(-maxNodeCoord, maxNodeCoord),
      y.clamp(-maxNodeCoord, maxNodeCoord),
    );
  }

  /// Evaluates whether placing a node at (candidateX, candidateY) is within world grid bounds.
  static bool isValidNodePosition({
    required double candidateX,
    required double candidateY,
    required String candidateId,
    required Iterable<Nodo> existingNodes,
    double nodeDiameter = 50.0,
  }) {
    return candidateX.abs() <= maxNodeCoord && candidateY.abs() <= maxNodeCoord;
  }

  /// Calculates clamped position within world grid bounds without distance jump restrictions.
  static Point2D getNearestValidPosition({
    required double candidateX,
    required double candidateY,
    required String candidateId,
    required Iterable<Nodo> existingNodes,
    double nodeDiameter = 50.0,
  }) {
    return clampNodePosition(candidateX, candidateY);
  }
}
