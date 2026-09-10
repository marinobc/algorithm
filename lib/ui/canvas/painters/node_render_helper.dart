import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../graph_render_model.dart';

class NodeRenderHelper {
  static void drawNode(
    Canvas canvas,
    RenderNode node,
    NeumorphicPalette palette,
  ) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.width,
      height: node.height,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(999), // M3 pill shape
    );

    if (node.isOverlapping) {
      canvas.saveLayer(
        rect.inflate(12.0),
        Paint()
          ..color = const Color(
            0x99FFFFFF,
          ), // 60% opacity for overlapping nodes
      );
    }

    // 1. Subtle Node Drop Shadow
    final shadowPath = Path()..addRRect(rrect);
    final isCanvasLight = palette.surfaceBg.computeLuminance() > 0.45;
    final shadowColor = isCanvasLight
        ? const Color(0x33000000)
        : const Color(0x66000000);
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

    if (node.isOverlapping) {
      canvas.restore();
    }
  }

  static void drawNodeHighlightUnderlay(
    Canvas canvas,
    RenderNode node,
    Color highlightBaseColor,
    NeumorphicPalette palette,
  ) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.width,
      height: node.height,
    );

    // Outer soft ambient glow fill
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

    // 3.0px inflated solid underlay fill
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
