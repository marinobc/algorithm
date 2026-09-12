import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../graph_render_model.dart';

class EdgeRenderHelper {
  static void drawConnection(
    Canvas canvas,
    RenderConnectionLine conn,
    NeumorphicPalette palette, {
    double opacity = 1.0,
  }) {
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

    // Selection background glow (manual selection)
    if (conn.isSelected && !conn.isHighlighted) {
      final highlightPaint = Paint()
        ..color = palette.primaryAccent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, highlightPaint);
    }

    // Main line paint
    final linePaint = Paint()
      ..color = conn.color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Arrow for directed connections
    if (conn.isDirected && conn.arrowPoint != null && conn.arrowAngle != null) {
      drawArrowHead(
        canvas,
        conn.arrowPoint!,
        conn.arrowAngle!,
        conn.color.withValues(alpha: opacity),
      );
    }

    if (conn.reverseArrowPoint != null && conn.reverseArrowAngle != null) {
      drawArrowHead(
        canvas,
        conn.reverseArrowPoint!,
        conn.reverseArrowAngle!,
        conn.color.withValues(alpha: opacity),
      );
    }

    // Connection label (Neumorphic attribute badge)
    if (conn.labelText != null &&
        conn.labelText!.isNotEmpty &&
        conn.labelPosition != null) {
      drawConnectionLabel(
        canvas,
        conn.labelText!,
        conn.labelPosition!,
        conn.color,
        palette,
        opacity: opacity,
      );
    }
  }

  static void drawDragLine(Canvas canvas, RenderDragLine dragLine) {
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
    drawArrowHead(canvas, end, angle, dragLine.color);
  }

  static Path getArrowPath(Offset tip, double angleRadians) {
    const arrowLength = 15.0;
    const arrowWidth = 11.0;
    const notchDepth = 4.5;

    final ux = cos(angleRadians);
    final uy = sin(angleRadians);
    final nx = -uy;
    final ny = ux;

    final bx = tip.dx - ux * arrowLength;
    final by = tip.dy - uy * arrowLength;

    final pLeft = Offset(
      bx + nx * (arrowWidth / 2),
      by + ny * (arrowWidth / 2),
    );
    final pRight = Offset(
      bx - nx * (arrowWidth / 2),
      by - ny * (arrowWidth / 2),
    );
    final pNotch = Offset(bx + ux * notchDepth, by + uy * notchDepth);

    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..quadraticBezierTo(pNotch.dx, pNotch.dy, pRight.dx, pRight.dy)
      ..close();
  }

  static void drawArrowHead(
    Canvas canvas,
    Offset tip,
    double angleRadians,
    Color color,
  ) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = getArrowPath(tip, angleRadians);
    canvas.drawPath(path, arrowPaint);
  }

  static void drawArrowHeadUnderlay(
    Canvas canvas,
    Offset tip,
    double angleRadians,
    Color highlightBaseColor,
    NeumorphicPalette palette,
  ) {
    final path = getArrowPath(tip, angleRadians);

    final glowPaint = Paint()
      ..color = highlightBaseColor.withValues(
        alpha: palette.isDark ? 0.45 : 0.3,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawPath(path, glowPaint);

    final solidPaint = Paint()
      ..color = highlightBaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, solidPaint);
  }

  static void drawConnectionLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    NeumorphicPalette palette, {
    double opacity = 1.0,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: palette.textPrimary.withValues(alpha: opacity),
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

    final bgPaint = Paint()
      ..color = palette.surfaceBg.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: opacity)
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

  static void drawConnectionLabelUnderlay(
    Canvas canvas,
    String text,
    Offset position,
    Color highlightBaseColor,
    NeumorphicPalette palette,
  ) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final baseRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 16,
      height: textPainter.height + 8,
    );

    final glowPaint = Paint()
      ..color = highlightBaseColor.withValues(
        alpha: palette.isDark ? 0.45 : 0.3,
      )
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    final glowRRect = RRect.fromRectAndRadius(
      baseRect.inflate(7.0),
      const Radius.circular(19),
    );
    canvas.drawRRect(glowRRect, glowPaint);

    final solidPaint = Paint()
      ..color = highlightBaseColor
      ..style = PaintingStyle.fill;
    final solidRRect = RRect.fromRectAndRadius(
      baseRect.inflate(3.0),
      const Radius.circular(15),
    );
    canvas.drawRRect(solidRRect, solidPaint);
  }
}
