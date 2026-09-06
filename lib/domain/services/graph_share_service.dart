import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/grafo.dart';
import '../../ui/canvas/graph_painter.dart';
import '../../ui/canvas/graph_render_model.dart';
import '../../ui/theme/app_theme.dart';

class GraphShareService {
  /// Generates a base64-encoded thumbnail with the canvas sized to match the
  /// graph's own bounding-box aspect ratio (long side ≤ [maxSize]).
  /// A tall graph produces a tall image; a wide graph produces a wide image.
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
      final renderModel = GraphRenderModel.fromGrafo(graph, palette: palette);

      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;

      for (final node in renderModel.nodes) {
        final halfW = node.width / 2.0 + 12.0;
        final halfH = node.height / 2.0 + 12.0;
        if (node.position.dx - halfW < minX) minX = node.position.dx - halfW;
        if (node.position.dx + halfW > maxX) maxX = node.position.dx + halfW;
        if (node.position.dy - halfH < minY) minY = node.position.dy - halfH;
        if (node.position.dy + halfH > maxY) maxY = node.position.dy + halfH;
      }

      for (final conn in renderModel.connections) {
        for (final p in [
          conn.curve.start,
          conn.curve.control1,
          conn.curve.control2,
          conn.curve.end,
        ]) {
          if (p.dx - 20 < minX) minX = p.dx - 20;
          if (p.dx + 20 > maxX) maxX = p.dx + 20;
          if (p.dy - 20 < minY) minY = p.dy - 20;
          if (p.dy + 20 > maxY) maxY = p.dy + 20;
        }
      }

      final totalW = (maxX - minX).abs();
      final totalH = (maxY - minY).abs();
      final centerX = (minX + maxX) / 2.0;
      final centerY = (minY + maxY) / 2.0;

      final margin = min(width, height) * 0.08;
      final scaleX = (width - margin * 2) / max(totalW, 40.0);
      final scaleY = (height - margin * 2) / max(totalH, 40.0);
      final fitScale = min(scaleX, scaleY).clamp(0.1, 10.0);

      final transform = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(width / 2, height / 2)
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

    // Draw graph name pill in top-left overlay of the exported image
    if (graphName != null && graphName.trim().isNotEmpty) {
      final textSpan = TextSpan(
        text: graphName.trim(),
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      const paddingH = 20.0;
      const paddingV = 10.0;
      const pillMargin = 32.0;

      final pillWidth = textPainter.width + paddingH * 2 + 28.0;
      final pillHeight = max(textPainter.height + paddingV * 2, 44.0);

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillMargin, pillMargin, pillWidth, pillHeight),
        const Radius.circular(999),
      );

      final shadowPath = Path()..addRRect(pillRect);
      canvas.drawShadow(
        shadowPath,
        Colors.black.withValues(alpha: 0.35),
        6.0,
        false,
      );

      final pillBgPaint = Paint()
        ..color = palette.surfaceBg.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(pillRect, pillBgPaint);

      final borderPaint = Paint()
        ..color = palette.primaryAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(pillRect, borderPaint);

      final iconCenter = Offset(
        pillMargin + paddingH + 6,
        pillMargin + pillHeight / 2,
      );
      final iconPaint = Paint()
        ..color = palette.primaryAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(iconCenter, 6.0, iconPaint);

      final innerDot = Paint()
        ..color = palette.surfaceBg
        ..style = PaintingStyle.fill;
      canvas.drawCircle(iconCenter, 2.5, innerDot);

      textPainter.paint(
        canvas,
        Offset(
          pillMargin + paddingH + 20.0,
          pillMargin + (pillHeight - textPainter.height) / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<String> _saveJpgFile(Uint8List bytes, String graphName) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'El guardado directo en archivo local no está disponible en la versión web.',
      );
    }

    String? dirPath;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloadsDir = Directory('$userProfile\\Downloads');
        if (downloadsDir.existsSync()) {
          dirPath = downloadsDir.path;
        }
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final docsDir = Directory('/storage/emulated/0/Download');
      if (docsDir.existsSync()) {
        dirPath = docsDir.path;
      }
    }

    dirPath ??= Directory.current.path;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = graphName.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
    final fileName =
        'grafo_${safeName.isEmpty ? "export" : safeName}_$timestamp.jpg';
    final filePath = '$dirPath${Platform.pathSeparator}$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  /// Displays a dialog showcasing the generated graph JPG image preview with a Save button.
  static void showSaveJpgDialog(
    BuildContext context,
    Grafo graph, {
    String? graphName,
  }) async {
    final palette = NeumorphicPalette.of(context);
    final jpgBytes = await generateGraphJpgBytes(
      graph,
      palette: palette,
      graphName: graphName,
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.save_alt_rounded, color: Colors.blue),
              SizedBox(width: 10),
              Text('Guardar Imagen JPG'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(jpgBytes, fit: BoxFit.contain, height: 240),
              ),
              const SizedBox(height: 12),
              const Text(
                'Imagen JPG del grafo generada para guardar en el dispositivo.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                try {
                  final savedPath =
                      await _saveJpgFile(jpgBytes, graphName ?? 'Grafo');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imagen guardada exitosamente en:\n$savedPath',
                        ),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(label: 'OK', onPressed: () {}),
                      ),
                    );
                    Navigator.of(ctx).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar la imagen: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Guardar JPG'),
            ),
          ],
        );
      },
    );
  }
}
