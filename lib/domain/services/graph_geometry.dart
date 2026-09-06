import 'dart:math';
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
  /// Calculate 12 connection points at 30-degree increments around node perimeter.
  static List<ConnectionPoint> get12ConnectionPoints(Nodo nodo) {
    final points = <ConnectionPoint>[];
    for (int i = 0; i < 12; i++) {
      final angle = i * (pi / 6.0); // 30 degrees = pi / 6
      final px = nodo.x + nodo.radius * cos(angle);
      final py = nodo.y + nodo.radius * sin(angle);
      points.add(ConnectionPoint(
        point: Point2D(px, py),
        angleRadians: angle,
        index: i,
      ));
    }
    return points;
  }

  /// Select the connection point closest in angle toward the target position (tx, ty).
  static ConnectionPoint selectBestConnectionPoint(Nodo nodo, double tx, double ty) {
    final dx = tx - nodo.x;
    final dy = ty - nodo.y;
    var targetAngle = atan2(dy, dx);
    if (targetAngle < 0) {
      targetAngle += 2 * pi;
    }

    final points = get12ConnectionPoints(nodo);
    ConnectionPoint best = points[0];
    double minDiff = 2 * pi;

    for (final cp in points) {
      double diff = (cp.angleRadians - targetAngle).abs();
      if (diff > pi) {
        diff = 2 * pi - diff;
      }
      if (diff < minDiff) {
        minDiff = diff;
        best = cp;
      }
    }
    return best;
  }

  /// Calculates exact perimeter anchor point at any angle [angleRadians] for a node (accounting for capsule width).
  static Point2D getPerimeterPoint(Nodo nodo, double angleRadians) {
    final textLength = (nodo.nombre ?? nodo.id).length;
    final estimatedTextWidth = textLength * 8.0 + 24.0;
    final halfW = max(nodo.radius, estimatedTextWidth / 2.0);
    final halfH = nodo.radius;

    final cosA = cos(angleRadians);
    final sinA = sin(angleRadians);
    final denom = sqrt((cosA * cosA) / (halfW * halfW) + (sinA * sinA) / (halfH * halfH));
    final scale = denom > 0 ? (1.0 / denom) : nodo.radius;

    return Point2D(nodo.x + cosA * scale, nodo.y + sinA * scale);
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
    final effectiveFactor = customCurvatura ?? (offsetFactor != 0.0 ? offsetFactor * 0.25 : 0.04);

    if (origen.id == destino.id) {
      // 360-Degree Circular Self-Loop connection oriented around loopAngle
      final centerAngle = loopAngle ?? (-pi / 2.0); // Top (-90 deg) by default
      final textLength = (origen.nombre ?? origen.id).length;
      final nodeOuterRadius = max(origen.radius, (textLength * 8.0 + 24.0) / 2.0);

      // Smooth circular loop radius calculation: grows cleanly with curvatura
      final loopRadius = nodeOuterRadius * (1.1 + (effectiveFactor < 0 ? 0.0 : effectiveFactor.clamp(0.0, 6.0)) * 0.6);

      // Symmetrical anchor points on node perimeter
      final startAngle = centerAngle + (pi / 4.5); // +40 deg
      final endAngle = centerAngle - (pi / 4.5);   // -40 deg

      final start = getPerimeterPoint(origen, startAngle);
      final end = getPerimeterPoint(origen, endAngle);

      // Circular cubic Bezier control points that form a smooth round loop
      final c1 = Point2D(
        origen.x + (nodeOuterRadius + loopRadius * 1.55) * cos(centerAngle + 0.52),
        origen.y + (nodeOuterRadius + loopRadius * 1.55) * sin(centerAngle + 0.52),
      );
      final c2 = Point2D(
        origen.x + (nodeOuterRadius + loopRadius * 1.55) * cos(centerAngle - 0.52),
        origen.y + (nodeOuterRadius + loopRadius * 1.55) * sin(centerAngle - 0.52),
      );

      return BezierCurve2D(
        start: start,
        control1: c1,
        control2: c2,
        end: end,
      );
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
    final adaptiveMagnitude = min(rawDist * 0.40, 36.0 + 75.0 * log(1.0 + rawDist / 120.0));

    if (offsetControlX != null && offsetControlY != null) {
      // Smooth exponential dampening so extreme 2D drag distances maintain proportional curve elegance
      final dampFactor = rawDist == 0 ? 1.0 : min(1.0, 1.2 * (1.0 - exp(-rawDist / 350.0)));
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

    final cpOrigen = selectBestConnectionPoint(origen, peakTargetX, peakTargetY);
    final cpDestino = selectBestConnectionPoint(destino, peakTargetX, peakTargetY);

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
  static const double maxNodeCoord = 2376.0; // 2400.0 - 24.0 radius (node stays inside 100x100 grid)

  /// Clamps node position so the entire node body stays strictly inside world grid [-2400, 2400].
  static Point2D clampNodePosition(double x, double y) {
    return Point2D(
      x.clamp(-maxNodeCoord, maxNodeCoord),
      y.clamp(-maxNodeCoord, maxNodeCoord),
    );
  }

  /// Evaluates whether placing a node at (candidateX, candidateY) violates
  /// minimum distance requirements (1 node diameter spacing) with existing nodes
  /// or exceeds the 100x100 world grid bounds.
  static bool isValidNodePosition({
    required double candidateX,
    required double candidateY,
    required String candidateId,
    required Iterable<Nodo> existingNodes,
    double nodeDiameter = 50.0,
  }) {
    if (candidateX.abs() > maxNodeCoord || candidateY.abs() > maxNodeCoord) {
      return false;
    }

    final minDistance = nodeDiameter * 2.0; // Distance between centers must be at least 2 * radius + 1 diameter = 2 diameters
    for (final node in existingNodes) {
      if (node.id == candidateId) continue;
      final dx = candidateX - node.x;
      final dy = candidateY - node.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < minDistance) {
        return false;
      }
    }
    return true;
  }

  /// Calculates the nearest valid position using a multi-pass iterative collision solver
  /// to ensure pushing candidate away from one node does not cause a collision with another node.
  static Point2D getNearestValidPosition({
    required double candidateX,
    required double candidateY,
    required String candidateId,
    required Iterable<Nodo> existingNodes,
    double nodeDiameter = 50.0,
  }) {
    double x = candidateX.clamp(-maxNodeCoord, maxNodeCoord);
    double y = candidateY.clamp(-maxNodeCoord, maxNodeCoord);
    final requiredDist = nodeDiameter * 2.0;

    // Multi-pass iterative resolution (recursive collision propagation prevention)
    const maxPasses = 15;
    for (int pass = 0; pass < maxPasses; pass++) {
      bool hasCollision = false;
      for (final node in existingNodes) {
        if (node.id == candidateId) continue;
        final dx = x - node.x;
        final dy = y - node.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < requiredDist) {
          hasCollision = true;
          if (dist == 0) {
            // Push at 45 degree angle if exact overlap
            x = (node.x + requiredDist * cos(pi / 4)).clamp(-maxNodeCoord, maxNodeCoord);
            y = (node.y + requiredDist * sin(pi / 4)).clamp(-maxNodeCoord, maxNodeCoord);
          } else {
            final factor = requiredDist / dist;
            x = (node.x + dx * factor).clamp(-maxNodeCoord, maxNodeCoord);
            y = (node.y + dy * factor).clamp(-maxNodeCoord, maxNodeCoord);
          }
        }
      }
      if (!hasCollision) break;
    }

    // Safety fallback: if multi-pass bound in tight cluster, perform radial search
    if (!isValidNodePosition(
        candidateX: x,
        candidateY: y,
        candidateId: candidateId,
        existingNodes: existingNodes,
        nodeDiameter: nodeDiameter)) {
      double angle = 0;
      double radiusOffset = requiredDist;
      while (radiusOffset <= maxNodeCoord * 2) {
        for (int i = 0; i < 8; i++) {
          final testX = (x + radiusOffset * cos(angle)).clamp(-maxNodeCoord, maxNodeCoord);
          final testY = (y + radiusOffset * sin(angle)).clamp(-maxNodeCoord, maxNodeCoord);
          if (isValidNodePosition(
              candidateX: testX,
              candidateY: testY,
              candidateId: candidateId,
              existingNodes: existingNodes,
              nodeDiameter: nodeDiameter)) {
            return Point2D(testX, testY);
          }
          angle += pi / 4;
        }
        radiusOffset += nodeDiameter;
      }
    }

    return Point2D(x, y);
  }
}
