import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'graph_render_model.dart';
import 'painters/edge_render_helper.dart';
import 'painters/node_render_helper.dart';

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

    // 2. Draw Algorithm Highlights Underlay Pass
    _drawAlgorithmHighlightsUnderlay(canvas);

    final hasAlgorithmPath = renderModel.connections.any(
      (connection) => connection.isHighlighted,
    );

    // Dim alternatives while an algorithm solution is active.
    for (final conn in renderModel.connections) {
      EdgeRenderHelper.drawConnection(
        canvas,
        conn,
        palette,
        opacity: hasAlgorithmPath && !conn.isHighlighted ? 0.18 : 1.0,
      );
    }

    // 3.5 Draw Live Drag-to-Connect Preview Line
    if (renderModel.dragLine != null) {
      EdgeRenderHelper.drawDragLine(canvas, renderModel.dragLine!);
    }

    // 4. Draw Neumorphic Nodes Pass
    for (final node in renderModel.nodes) {
      NodeRenderHelper.drawNode(canvas, node, palette);
    }

    // Keep the selected path, arrows and values above the nodes.
    if (hasAlgorithmPath) {
      for (final conn in renderModel.connections.where(
        (connection) => connection.isHighlighted,
      )) {
        EdgeRenderHelper.drawConnection(canvas, conn, palette);
      }
    }

    canvas.restore();
  }

  void _drawDottedGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = palette.canvasGridDots
      ..style = PaintingStyle.fill;

    const gridStep = 48.0;
    const startX = -2400.0;
    const endX = 2400.0;
    const startY = -2400.0;
    const endY = 2400.0;

    for (double x = startX; x <= endX; x += gridStep) {
      for (double y = startY; y <= endY; y += gridStep) {
        canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
      }
    }
  }

  void _drawAlgorithmHighlightsUnderlay(Canvas canvas) {
    final highlightBaseColor = palette.isDark ? Colors.white : Colors.black;

    // 1. Highlighted Connections
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

      final glowBgPaint = Paint()
        ..color = highlightBaseColor.withValues(
          alpha: palette.isDark ? 0.45 : 0.3,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(path, glowBgPaint);

      final solidUnderlayPaint = Paint()
        ..color = highlightBaseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, solidUnderlayPaint);

      if (conn.isDirected &&
          conn.arrowPoint != null &&
          conn.arrowAngle != null) {
        EdgeRenderHelper.drawArrowHeadUnderlay(
          canvas,
          conn.arrowPoint!,
          conn.arrowAngle!,
          highlightBaseColor,
          palette,
        );
      }
      if (conn.reverseArrowPoint != null && conn.reverseArrowAngle != null) {
        EdgeRenderHelper.drawArrowHeadUnderlay(
          canvas,
          conn.reverseArrowPoint!,
          conn.reverseArrowAngle!,
          highlightBaseColor,
          palette,
        );
      }

      if (conn.labelText != null &&
          conn.labelText!.isNotEmpty &&
          conn.labelPosition != null) {
        EdgeRenderHelper.drawConnectionLabelUnderlay(
          canvas,
          conn.labelText!,
          conn.labelPosition!,
          highlightBaseColor,
          palette,
        );
      }
    }

    // 2. Highlighted Nodes
    for (final node in renderModel.nodes.where((n) => n.isHighlighted)) {
      NodeRenderHelper.drawNodeHighlightUnderlay(
        canvas,
        node,
        highlightBaseColor,
        palette,
      );
    }
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
