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

    // 2. Draw Algorithm Highlights Underlay Pass (Renders behind all graph elements)
    _drawAlgorithmHighlightsUnderlay(canvas);

    // 3. Draw Main Connections Pass
    for (final conn in renderModel.connections) {
      _drawConnection(canvas, conn);
    }

    // 3.5 Draw Live Drag-to-Connect Preview Line
    if (renderModel.dragLine != null) {
      _drawDragLine(canvas, renderModel.dragLine!);
    }

    // 4. Draw Neumorphic Nodes Pass
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
    const endX = 2400.0; // 50 nodes right of origin
    const startY = -2400.0; // 50 nodes above origin
    const endY = 2400.0; // 50 nodes below origin

    for (double x = startX; x <= endX; x += gridStep) {
      for (double y = startY; y <= endY; y += gridStep) {
        canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
      }
    }
  }

  /// Dedicated Underlay Pass for Algorithm Highlights (Nodes, Connections, and Arrowheads).
  /// Placed completely behind the main graph to prevent overlapping edge line clutter.
  /// Uses White highlight in dark mode and Black highlight in light mode.
  /// Both nodes and connections extend exactly 3.0px of solid underlay + 4.0px glow on all sides.
  void _drawAlgorithmHighlightsUnderlay(Canvas canvas) {
    final highlightBaseColor = palette.isDark ? Colors.white : Colors.black;

    // 1. Highlighted Connections (3.0px Extra Solid Underlay Outline + Ambient Outer Glow)
    // Main line = 2.5px width. Underlay solid line = 8.5px width (extends 3.0px beyond line on each side).
    for (final conn in renderModel.connections.where((c) => c.isHighlighted)) {
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

      // Outer soft ambient glow (16.5px stroke => extends 7.0px from main line, matching node inflate 7.0)
      final glowBgPaint = Paint()
        ..color = highlightBaseColor.withValues(
          alpha: palette.isDark ? 0.45 : 0.3,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(path, glowBgPaint);

      // 3.0px extra solid underlay outline (8.5px stroke => extends 3.0px from main line)
      final solidUnderlayPaint = Paint()
        ..color = highlightBaseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, solidUnderlayPaint);

      // Highlight arrowhead tips in underlay pass
      if (conn.isDirected &&
          conn.arrowPoint != null &&
          conn.arrowAngle != null) {
        _drawArrowHeadUnderlay(
          canvas,
          conn.arrowPoint!,
          conn.arrowAngle!,
          highlightBaseColor,
        );
      }
      if (conn.reverseArrowPoint != null && conn.reverseArrowAngle != null) {
        _drawArrowHeadUnderlay(
          canvas,
          conn.reverseArrowPoint!,
          conn.reverseArrowAngle!,
          highlightBaseColor,
        );
      }

      // Highlight connection value label badge in underlay pass
      if (conn.labelText != null &&
          conn.labelText!.isNotEmpty &&
          conn.labelPosition != null) {
        _drawConnectionLabelUnderlay(
          canvas,
          conn.labelText!,
          conn.labelPosition!,
          highlightBaseColor,
        );
      }
    }

    // 2. Highlighted Nodes (3.0px Inflated Solid Underlay Halo + Ambient Outer Glow)
    for (final node in renderModel.nodes.where((n) => n.isHighlighted)) {
      final rect = Rect.fromCenter(
        center: node.position,
        width: node.width,
        height: node.height,
      );

      // Outer soft ambient glow fill (inflate 7.0 => extends 7.0px from node edge)
      final auraPaint = Paint()
        ..color = highlightBaseColor.withValues(
          alpha: palette.isDark ? 0.45 : 0.3,
        )
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      final auraRRect = RRect.fromRectAndRadius(
        rect.inflate(7.0),
        const Radius.circular(999),
      );
      canvas.drawRRect(auraRRect, auraPaint);

      // 3.0px inflated solid underlay fill (extends 3.0px beyond node boundary)
      final solidFillPaint = Paint()
        ..color = highlightBaseColor
        ..style = PaintingStyle.fill;
      final solidRRect = RRect.fromRectAndRadius(
        rect.inflate(3.0),
        const Radius.circular(999),
      );
      canvas.drawRRect(solidRRect, solidFillPaint);
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

    // Selection background glow (manual selection)
    if (conn.isSelected && !conn.isHighlighted) {
      final highlightPaint = Paint()
        ..color = palette.primaryAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, highlightPaint);
    }

    // Main line paint (preserves original connection color in the upper graph layer)
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
      _drawArrowHead(
        canvas,
        conn.reverseArrowPoint!,
        conn.reverseArrowAngle!,
        conn.color,
      );
    }

    // Connection label (Neumorphic attribute badge)
    if (conn.labelText != null &&
        conn.labelText!.isNotEmpty &&
        conn.labelPosition != null) {
      _drawConnectionLabel(
        canvas,
        conn.labelText!,
        conn.labelPosition!,
        conn.color,
      );
    }
  }

  Path _getArrowPath(Offset tip, double angleRadians) {
    const arrowLength = 15.0;
    const arrowWidth = 11.0;
    const notchDepth = 4.5; // Depth of aerodynamic concave back curve

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

  void _drawArrowHeadUnderlay(
    Canvas canvas,
    Offset tip,
    double angleRadians,
    Color highlightBaseColor,
  ) {
    final path = _getArrowPath(tip, angleRadians);

    // Outer soft ambient glow for stealth arrowhead (strokeWidth 14.0 => extends 7.0px on all sides)
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

    // 3.0px extra solid underlay outline for stealth arrowhead (strokeWidth 6.0 => extends 3.0px on all sides)
    final solidPaint = Paint()
      ..color = highlightBaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, solidPaint);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    double angleRadians,
    Color color,
  ) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = _getArrowPath(tip, angleRadians);
    canvas.drawPath(path, arrowPaint);
  }

  void _drawConnectionLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
  ) {
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

  void _drawConnectionLabelUnderlay(
    Canvas canvas,
    String text,
    Offset position,
    Color highlightBaseColor,
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

    // 1. Soft ambient glow background (inflated by 7.0px on all sides)
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

    // 2. Solid 3.0px inflated underlay fill (extends 3.0px beyond badge border on all sides)
    final solidPaint = Paint()
      ..color = highlightBaseColor
      ..style = PaintingStyle.fill;
    final solidRRect = RRect.fromRectAndRadius(
      baseRect.inflate(3.0),
      const Radius.circular(15),
    );
    canvas.drawRRect(solidRRect, solidPaint);
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
        : const Color(
            0x66000000,
          ); // Soft ambient drop shadow on dark background
    canvas.drawShadow(shadowPath, shadowColor, 3.5, false);

    // 2. Main Node Surface Fill
    final surfaceColor = node.color;
    final lum = surfaceColor.computeLuminance();
    final isBright = lum > 0.45;

    final nodePaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, nodePaint);

    // 3. Selection / Pending Target Ring (Highlighted nodes already have underlay aura)
    if (node.isSelected || node.isPendingConnectTarget) {
      final highlightPaint = Paint()
        ..color = node.isSelected
            ? palette.primaryAccent
            : palette.secondaryAccent
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
