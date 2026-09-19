import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AlgorithmCatalogIllustration {
  freeMode,
  assignment,
  johnson,
  northwest,
  upcoming,
}

class AlgorithmCatalogIllustrationWidget extends StatelessWidget {
  final AlgorithmCatalogIllustration illustration;
  final Color accentColor;

  const AlgorithmCatalogIllustrationWidget({
    super.key,
    required this.illustration,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AlgorithmCatalogIllustrationPainter(
        illustration: illustration,
        accentColor: accentColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AlgorithmCatalogIllustrationPainter extends CustomPainter {
  final AlgorithmCatalogIllustration illustration;
  final Color accentColor;

  const _AlgorithmCatalogIllustrationPainter({
    required this.illustration,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final nodePaint = Paint()..color = accentColor;
    final mutedNodePaint = Paint()..color = accentColor.withValues(alpha: 0.45);

    switch (illustration) {
      case AlgorithmCatalogIllustration.freeMode:
        _drawFreeGraph(canvas, size, linePaint, nodePaint, mutedNodePaint);
      case AlgorithmCatalogIllustration.assignment:
        _drawBipartiteGraph(canvas, size, linePaint, nodePaint, mutedNodePaint);
      case AlgorithmCatalogIllustration.johnson:
        _drawDirectedGraph(canvas, size, linePaint, nodePaint, mutedNodePaint);
      case AlgorithmCatalogIllustration.northwest:
        _drawBipartiteGraph(canvas, size, linePaint, nodePaint, mutedNodePaint);
      case AlgorithmCatalogIllustration.upcoming:
        _drawUpcomingGraph(canvas, size, linePaint, mutedNodePaint);
    }
  }

  void _drawFreeGraph(
    Canvas canvas,
    Size size,
    Paint line,
    Paint node,
    Paint muted,
  ) {
    final points = [
      Offset(size.width * .24, size.height * .56),
      Offset(size.width * .48, size.height * .30),
      Offset(size.width * .70, size.height * .54),
      Offset(size.width * .47, size.height * .72),
      Offset(size.width * .76, size.height * .76),
    ];
    const edges = [(0, 1), (0, 3), (1, 2), (1, 3), (2, 3), (2, 4)];
    for (final edge in edges) {
      canvas.drawLine(points[edge.$1], points[edge.$2], line);
    }
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], i == 1 ? 11 : 9.5, i.isEven ? node : muted);
      canvas.drawCircle(
        points[i],
        i == 1 ? 11 : 9.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawBipartiteGraph(
    Canvas canvas,
    Size size,
    Paint line,
    Paint node,
    Paint muted,
  ) {
    final left = [
      Offset(size.width * .28, size.height * .32),
      Offset(size.width * .28, size.height * .68),
    ];
    final right = [
      Offset(size.width * .72, size.height * .26),
      Offset(size.width * .72, size.height * .50),
      Offset(size.width * .72, size.height * .74),
    ];
    for (final origin in left) {
      for (final destination in right) {
        canvas.drawLine(origin, destination, line);
      }
    }
    for (final point in left) {
      canvas.drawCircle(point, 10.5, muted);
      canvas.drawCircle(
        point,
        10.5,
        Paint()
          ..color = Colors.white.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    for (final point in right) {
      canvas.drawCircle(point, 10.5, node);
      canvas.drawCircle(
        point,
        10.5,
        Paint()
          ..color = Colors.white.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawDirectedGraph(
    Canvas canvas,
    Size size,
    Paint line,
    Paint node,
    Paint muted,
  ) {
    final points = [
      Offset(size.width * .50, size.height * .24),
      Offset(size.width * .28, size.height * .66),
      Offset(size.width * .72, size.height * .66),
    ];
    _drawArrow(canvas, points[0], points[1], line);
    _drawArrow(canvas, points[0], points[2], line);
    _drawArrow(canvas, points[2], points[1], line);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 11, i == 0 ? node : muted);
      canvas.drawCircle(
        points[i],
        11,
        Paint()
          ..color = Colors.white.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawUpcomingGraph(Canvas canvas, Size size, Paint line, Paint muted) {
    final center = Offset(size.width * .50, size.height * .50);
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 3);
      final point = center + Offset(math.cos(angle) * 48, math.sin(angle) * 42);
      canvas.drawLine(
        center,
        point,
        line..color = line.color.withValues(alpha: .28),
      );
      canvas.drawCircle(point, 13, muted);
    }
    canvas.drawCircle(center, 18, muted);
    final painter = TextPainter(
      text: TextSpan(
        text: '...',
        style: TextStyle(
          color: Colors.white.withValues(alpha: .8),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const length = 10.0;
    final wingA =
        end -
        Offset(math.cos(angle - .55) * length, math.sin(angle - .55) * length);
    final wingB =
        end -
        Offset(math.cos(angle + .55) * length, math.sin(angle + .55) * length);
    canvas.drawLine(end, wingA, paint);
    canvas.drawLine(end, wingB, paint);
  }

  @override
  bool shouldRepaint(
    covariant _AlgorithmCatalogIllustrationPainter oldDelegate,
  ) {
    return oldDelegate.illustration != illustration ||
        oldDelegate.accentColor != accentColor;
  }
}
