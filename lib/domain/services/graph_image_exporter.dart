import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/utils/platform_file_saver_stub.dart'
    if (dart.library.js_interop) '../../core/utils/platform_file_saver_web.dart'
    if (dart.library.io) '../../core/utils/platform_file_saver_io.dart';
import '../../ui/canvas/graph_painter.dart';
import '../../ui/canvas/graph_render_model.dart';
import '../../ui/theme/app_theme.dart';
import '../models/grafo.dart';
import 'diceware_service.dart';

/// Pure domain/rendering service for exporting graph graphics to byte arrays and base64 strings.
class GraphImageExporter {
  /// Generates a base64-encoded thumbnail with the canvas sized to match the
  /// graph's own bounding-box aspect ratio (long side <= [maxSize]).
  static Future<String?> generateThumbnailBase64(
    Grafo graph, {
    double maxSize = 960,
  }) async {
    if (graph.nodos.isEmpty) return null;
    try {
      final palette = NeumorphicPalette.dark;
      final model = GraphRenderModel.fromGrafo(graph, palette: palette);

      double minX = double.infinity, maxX = -double.infinity;
      double minY = double.infinity, maxY = -double.infinity;

      for (final node in model.nodes) {
        final halfW = node.width / 2.0 + 8.0;
        final halfH = node.height / 2.0 + 8.0;
        if (node.position.dx - halfW < minX) minX = node.position.dx - halfW;
        if (node.position.dx + halfW > maxX) maxX = node.position.dx + halfW;
        if (node.position.dy - halfH < minY) minY = node.position.dy - halfH;
        if (node.position.dy + halfH > maxY) maxY = node.position.dy + halfH;
      }

      for (final conn in model.connections) {
        for (final p in [
          conn.curve.start,
          conn.curve.control1,
          conn.curve.control2,
          conn.curve.end,
        ]) {
          if (p.dx - 16 < minX) minX = p.dx - 16;
          if (p.dx + 16 > maxX) maxX = p.dx + 16;
          if (p.dy - 16 < minY) minY = p.dy - 16;
          if (p.dy + 16 > maxY) maxY = p.dy + 16;
        }
      }

      final rawW = max((maxX - minX).abs(), 40.0);
      final rawH = max((maxY - minY).abs(), 40.0);
      final aspect = rawW / rawH;

      final double thumbW, thumbH;
      if (aspect >= 1.0) {
        thumbW = maxSize;
        thumbH = (maxSize / aspect).clamp(1.0, maxSize);
      } else {
        thumbH = maxSize;
        thumbW = (maxSize * aspect).clamp(1.0, maxSize);
      }

      final bytes = await generateGraphJpgBytes(
        graph,
        backgroundColor: Colors.transparent,
        showGrid: false,
        width: thumbW,
        height: thumbH,
        graphName: null,
      );
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Captures the given [graph] state into a high-resolution JPG image byte array.
  static Future<Uint8List> generateGraphJpgBytes(
    Grafo graph, {
    NeumorphicPalette palette = NeumorphicPalette.dark,
    double width = 1920,
    double height = 1080,
    Color? backgroundColor,
    bool showGrid = true,
    String? graphName,
    Set<String> highlightedNodeIds = const {},
    Set<String> highlightedConnectionIds = const {},
    String? solutionTitle,
    String? solutionValue,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fill background if not transparent
    if (backgroundColor != Colors.transparent) {
      final bgPaint = Paint()..color = backgroundColor ?? palette.canvasBg;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);
    }

    if (graph.nodos.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Grafo Vacío',
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((width - tp.width) / 2, (height - tp.height) / 2),
      );
    } else {
      final renderModel = GraphRenderModel.fromGrafo(
        graph,
        palette: palette,
        highlightedNodeIds: highlightedNodeIds,
        highlightedConnectionIds: highlightedConnectionIds,
      );

      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;

      for (final node in renderModel.nodes) {
        final namePainter = TextPainter(
          text: TextSpan(
            text: node.nombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final nodeW = max(node.width, namePainter.width + 16.0);
        final halfW = nodeW / 2.0 + 24.0;
        final halfH = node.height / 2.0 + 24.0;

        if (node.position.dx - halfW < minX) minX = node.position.dx - halfW;
        if (node.position.dx + halfW > maxX) maxX = node.position.dx + halfW;
        if (node.position.dy - halfH < minY) minY = node.position.dy - halfH;
        if (node.position.dy + halfH > maxY) maxY = node.position.dy + halfH;

        if (node.quantityLabel != null && node.quantityLabel!.isNotEmpty) {
          final qPainter = TextPainter(
            text: TextSpan(
              text: node.quantityLabel!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final qW = qPainter.width + 20.0;
          final qH = qPainter.height + 12.0;

          if (node.quantityLabelOnLeft) {
            final labelLeft = node.position.dx - halfW - qW - 12.0;
            if (labelLeft < minX) minX = labelLeft;
          } else if (node.quantityLabelBelow) {
            final labelBottom = node.position.dy + halfH + qH + 12.0;
            if (labelBottom > maxY) maxY = labelBottom;
          } else {
            if (node.position.dx - halfW - qW < minX) {
              minX = node.position.dx - halfW - qW;
            }
            if (node.position.dx + halfW + qW > maxX) {
              maxX = node.position.dx + halfW + qW;
            }
          }
        }
      }

      for (final conn in renderModel.connections) {
        final c = conn.curve;
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final u = 1 - t;
          final bx =
              u * u * u * c.start.dx +
              3 * u * u * t * c.control1.dx +
              3 * u * t * t * c.control2.dx +
              t * t * t * c.end.dx;
          final by =
              u * u * u * c.start.dy +
              3 * u * u * t * c.control1.dy +
              3 * u * t * t * c.control2.dy +
              t * t * t * c.end.dy;

          if (bx - 36.0 < minX) minX = bx - 36.0;
          if (bx + 36.0 > maxX) maxX = bx + 36.0;
          if (by - 36.0 < minY) minY = by - 36.0;
          if (by + 36.0 > maxY) maxY = by + 36.0;
        }

        if (conn.labelText != null &&
            conn.labelText!.isNotEmpty &&
            conn.labelPosition != null) {
          final lblPainter = TextPainter(
            text: TextSpan(
              text: conn.labelText!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final halfLblW = lblPainter.width / 2.0 + 24.0;
          final halfLblH = lblPainter.height / 2.0 + 16.0;
          final lx = conn.labelPosition!.dx;
          final ly = conn.labelPosition!.dy;

          if (lx - halfLblW < minX) minX = lx - halfLblW;
          if (lx + halfLblW > maxX) maxX = lx + halfLblW;
          if (ly - halfLblH < minY) minY = ly - halfLblH;
          if (ly + halfLblH > maxY) maxY = ly + halfLblH;
        }
      }

      final gName = graphName?.trim();
      final sTitle = solutionTitle?.trim();
      final hasName = gName != null && gName.isNotEmpty;
      final hasSolution = sTitle != null && sTitle.isNotEmpty;

      double cardHeight = 0.0;
      if (hasName || hasSolution) {
        const pillMargin = 36.0;
        const paddingV = 18.0;

        final titlePainter = TextPainter(
          text: TextSpan(
            text: (hasName ? gName : 'Grafo'),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        TextPainter? solTitlePainter;
        TextPainter? solValuePainter;

        if (hasSolution) {
          solTitlePainter = TextPainter(
            text: TextSpan(
              text: sTitle,
              style: TextStyle(
                color: palette.primaryAccent,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          if (solutionValue != null && solutionValue.trim().isNotEmpty) {
            solValuePainter = TextPainter(
              text: TextSpan(
                text: solutionValue.trim(),
                style: TextStyle(
                  color: palette.isDark ? Colors.white : Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
          }
        }

        double contentHeight = titlePainter.height;
        if (solTitlePainter != null) {
          contentHeight += solTitlePainter.height + 6.0;
        }
        if (solValuePainter != null) {
          contentHeight += solValuePainter.height + 8.0;
        }

        cardHeight = pillMargin + contentHeight + paddingV * 2;
      }

      final double sideMargin = min(100.0, width * 0.08);
      final double cardMargin = (hasName || hasSolution)
          ? cardHeight + 48.0
          : 0.0;
      final double marginV = max(sideMargin, cardMargin);
      final double marginH = sideMargin;

      final totalW = max((maxX - minX).abs(), 40.0);
      final totalH = max((maxY - minY).abs(), 40.0);
      final centerX = (minX + maxX) / 2.0;
      final centerY = (minY + maxY) / 2.0;

      final availW = width - marginH * 2;
      final availH = height - marginV * 2;

      final scaleX = availW / totalW;
      final scaleY = availH / totalH;
      final fitScale = min(scaleX, scaleY).clamp(0.1, 10.0);

      final targetCenterX = width / 2.0;
      final targetCenterY = height / 2.0;

      final transform = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(targetCenterX, targetCenterY)
        // ignore: deprecated_member_use
        ..scale(fitScale, fitScale, 1.0)
        // ignore: deprecated_member_use
        ..translate(-centerX, -centerY);

      final painter = GraphPainter(
        renderModel: renderModel,
        transform: transform,
        palette: palette,
        showGrid: showGrid,
      );

      painter.paint(canvas, Size(width, height));
    }

    // Draw graph name and active solution overlay card in top-left of the exported image
    final gName = graphName?.trim();
    final sTitle = solutionTitle?.trim();
    final hasName = gName != null && gName.isNotEmpty;
    final hasSolution = sTitle != null && sTitle.isNotEmpty;

    if (hasName || hasSolution) {
      const pillMargin = 36.0;
      const paddingH = 24.0;
      const paddingV = 18.0;

      final titlePainter = TextPainter(
        text: TextSpan(
          text: (hasName ? gName : 'Grafo'),
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      TextPainter? solTitlePainter;
      TextPainter? solValuePainter;

      if (hasSolution) {
        solTitlePainter = TextPainter(
          text: TextSpan(
            text: sTitle,
            style: TextStyle(
              color: palette.primaryAccent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        if (solutionValue != null && solutionValue.trim().isNotEmpty) {
          solValuePainter = TextPainter(
            text: TextSpan(
              text: solutionValue.trim(),
              style: TextStyle(
                color: palette.isDark ? Colors.white : Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
        }
      }

      double contentWidth = titlePainter.width;
      double contentHeight = titlePainter.height;

      if (solTitlePainter != null) {
        contentWidth = max(contentWidth, solTitlePainter.width);
        contentHeight += solTitlePainter.height + 6.0;
      }
      if (solValuePainter != null) {
        contentWidth = max(contentWidth, solValuePainter.width);
        contentHeight += solValuePainter.height + 8.0;
      }

      final cardWidth = contentWidth + paddingH * 2 + 24.0;
      final cardHeight = contentHeight + paddingV * 2;

      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillMargin, pillMargin, cardWidth, cardHeight),
        const Radius.circular(22),
      );

      final shadowPath = Path()..addRRect(cardRect);
      canvas.drawShadow(
        shadowPath,
        Colors.black.withValues(alpha: 0.45),
        12.0,
        false,
      );

      final cardBgPaint = Paint()
        ..color = palette.surfaceBg.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(cardRect, cardBgPaint);

      final borderPaint = Paint()
        ..color = palette.primaryAccent.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawRRect(cardRect, borderPaint);

      var currY = pillMargin + paddingV;

      titlePainter.paint(canvas, Offset(pillMargin + paddingH, currY));
      currY += titlePainter.height + 6.0;

      if (solTitlePainter != null) {
        solTitlePainter.paint(canvas, Offset(pillMargin + paddingH, currY));
        currY += solTitlePainter.height + 8.0;
      }

      if (solValuePainter != null) {
        solValuePainter.paint(canvas, Offset(pillMargin + paddingH, currY));
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static String generateUniqueExportFileName(
    String extension, {
    String? dirPath,
  }) {
    String name;
    do {
      name = generateDicewareName();
    } while (dirPath != null && checkFileExists('$dirPath/$name.$extension'));
    return '$name.$extension';
  }

  static Future<String> saveJpgFile(Uint8List bytes, String graphName) async {
    final fileName = generateUniqueExportFileName('png');
    final savedPath = await savePlatformBytes(
      fileName,
      bytes,
      mimeType: 'image/png',
    );
    return savedPath ?? fileName;
  }
}
