import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'graph_render_model.dart';

class GraphPainter extends CustomPainter {
  final GraphRenderModel renderModel;
  final Matrix4 transform;
  final NeumorphicPalette palette;

  final bool showGrid;

  GraphPainter({
    required this.renderModel,
    required this.transform,
    this.palette = NeumorphicPalette.dark,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save canvas state
    canvas.save();

    // Apply zoom/pan transformation
    canvas.transform(transform.storage);

    // 1. Draw Dotted Grid Background
    if (showGrid) {
      _drawDottedGrid(canvas, size);
    }

    // 2. Draw Connections
    for (final conn in renderModel.connections) {
      _drawConnection(canvas, conn);
    }

    // 2.5 Draw Live Drag-to-Connect Preview Line
    if (renderModel.dragLine != null) {
      _drawDragLine(canvas, renderModel.dragLine!);
    }

    // 3. Draw Neumorphic Nodes
    for (final node in renderModel.nodes) {
      _drawNode(canvas, node);
    }

    canvas.restore();
  }

  void _drawDottedGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = palette.canvasGridDots
      ..style = PaintingStyle.fill;

    const gridStep = 48.0; // 1 node diameter (U)
    const startX = -2400.0; // 50 nodes left of origin
    const endX = 2400.0;   // 50 nodes right of origin
    const startY = -2400.0; // 50 nodes above origin
    const endY = 2400.0;   // 50 nodes below origin

    for (double x = startX; x <= endX; x += gridStep) {
      for (double y = startY; y <= endY; y += gridStep) {
        canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
      }
    }
  }

  void _drawDragLine(Canvas canvas, RenderDragLine dragLine) {
    final start = dragLine.start;
    final end = dragLine.end;

    final glowPaint = Paint()
      ..color = dragLine.color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, glowPaint);

    final linePaint = Paint()
      ..color = dragLine.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, linePaint);

    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    _drawArrowHead(canvas, end, angle, dragLine.color);
  }

  void _drawConnection(Canvas canvas, RenderConnectionLine conn) {
    final path = Path()
      ..moveTo(conn.curve.start.dx, conn.curve.start.dy)
      ..cubicTo(
        conn.curve.control1.dx,
        conn.curve.control1.dy,
        conn.curve.control2.dx,
        conn.curve.control2.dy,
        conn.curve.end.dx,
        conn.curve.end.dy,
      );

    // Highlight / selection shadow glow
    if (conn.isSelected || conn.isHighlighted) {
      final highlightPaint = Paint()
        ..color = conn.isSelected
            ? palette.primaryAccent
            : palette.secondaryAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = conn.isSelected ? 6.0 : 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, highlightPaint);
    }

    // Main line paint
    final linePaint = Paint()
      ..color = conn.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Arrow for directed connections
    if (conn.isDirected && conn.arrowPoint != null && conn.arrowAngle != null) {
      _drawArrowHead(canvas, conn.arrowPoint!, conn.arrowAngle!, conn.color);
    }

    if (conn.reverseArrowPoint != null && conn.reverseArrowAngle != null) {
      _drawArrowHead(canvas, conn.reverseArrowPoint!, conn.reverseArrowAngle!, conn.color);
    }

    // Connection label (Neumorphic attribute badge)
    if (conn.labelText != null &&
        conn.labelText!.isNotEmpty &&
        conn.labelPosition != null) {
      _drawConnectionLabel(
          canvas, conn.labelText!, conn.labelPosition!, conn.color);
    }
  }

  void _drawArrowHead(
      Canvas canvas, Offset tip, double angleRadians, Color color) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const arrowLength = 14.0;
    const arrowWidth = 10.0;

    final ux = cos(angleRadians);
    final uy = sin(angleRadians);
    final nx = -uy;
    final ny = ux;

    final bx = tip.dx - ux * arrowLength;
    final by = tip.dy - uy * arrowLength;

    final pLeft = Offset(bx + nx * (arrowWidth / 2), by + ny * (arrowWidth / 2));
    final pRight = Offset(bx - nx * (arrowWidth / 2), by - ny * (arrowWidth / 2));

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  void _drawConnectionLabel(
      Canvas canvas, String text, Offset position, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(12),
    );

    // Neumorphic/M3 badge background
    final bgPaint = Paint()
      ..color = palette.surfaceBg
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(bgRect, bgPaint);
    canvas.drawRRect(bgRect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawNode(Canvas canvas, RenderNode node) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.width,
      height: node.height,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(999), // M3 pill shape
    );
    // 1. Subtle Node Drop Shadow for Dark and Light Modes
    final shadowPath = Path()..addRRect(rrect);
    final isCanvasLight = palette.surfaceBg.computeLuminance() > 0.45;
    final shadowColor = isCanvasLight
        ? const Color(0x33000000) // Soft dark drop shadow on light background
        : const Color(0x66000000); // Soft ambient drop shadow on dark background
    canvas.drawShadow(shadowPath, shadowColor, 3.5, false);

    // 2. Main Node Surface Fill
    final surfaceColor = node.color;
    final lum = surfaceColor.computeLuminance();
    final isBright = lum > 0.45;

    final nodePaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, nodePaint);

    // 3. Selection / Pending Target Ring
    if (node.isSelected || node.isPendingConnectTarget || node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = node.isSelected
            ? palette.primaryAccent
            : (node.isPendingConnectTarget
                ? palette.secondaryAccent
                : palette.primaryAccent.withValues(alpha: 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.isSelected ? 3.5 : 2.5;

      final highlightRRect = RRect.fromRectAndRadius(
        rect.inflate(3.0),
        const Radius.circular(999),
      );
      canvas.drawRRect(highlightRRect, highlightPaint);
    }

    // 4. High-contrast Node Label Text
    final textColor = isBright ? Colors.black : Colors.white;

    final textSpan = TextSpan(
      text: node.nombre,
      style: TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        node.position.dx - textPainter.width / 2,
        node.position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    if (oldDelegate.renderModel != renderModel ||
        oldDelegate.palette != palette) {
      return true;
    }
    final a = oldDelegate.transform.storage;
    final b = transform.storage;
    for (int i = 0; i < 16; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
}
