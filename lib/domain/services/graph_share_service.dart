import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_toast.dart';
import '../models/grafo.dart';
import 'graph_image_exporter.dart';

/// Facade service handling user interactions and UI dialogs for graph sharing & exporting.
class GraphShareService {
  /// Delegates thumbnail base64 generation to [GraphImageExporter].
  static Future<String?> generateThumbnailBase64(
    Grafo graph, {
    double maxSize = 960,
  }) {
    return GraphImageExporter.generateThumbnailBase64(graph, maxSize: maxSize);
  }

  /// Delegates JPG image bytes rendering to [GraphImageExporter].
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
  }) {
    return GraphImageExporter.generateGraphJpgBytes(
      graph,
      palette: palette,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      showGrid: showGrid,
      graphName: graphName,
      highlightedNodeIds: highlightedNodeIds,
      highlightedConnectionIds: highlightedConnectionIds,
      solutionTitle: solutionTitle,
      solutionValue: solutionValue,
    );
  }

  /// Delegates filename generation to [GraphImageExporter].
  static String generateUniqueExportFileName(
    String extension, {
    String? dirPath,
  }) {
    return GraphImageExporter.generateUniqueExportFileName(
      extension,
      dirPath: dirPath,
    );
  }

  /// Displays a dialog showcasing the generated graph JPG image preview with a Save button.
  static void showSaveJpgDialog(
    BuildContext context,
    Grafo graph, {
    String? graphName,
    Set<String> highlightedNodeIds = const {},
    Set<String> highlightedConnectionIds = const {},
    String? solutionTitle,
    String? solutionValue,
  }) async {
    final palette = NeumorphicPalette.of(context);
    final jpgBytes = await generateGraphJpgBytes(
      graph,
      palette: palette,
      graphName: graphName,
      highlightedNodeIds: highlightedNodeIds,
      highlightedConnectionIds: highlightedConnectionIds,
      solutionTitle: solutionTitle,
      solutionValue: solutionValue,
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
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(
                    jpgBytes,
                    fit: BoxFit.contain,
                    height: 260,
                  ),
                ),
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
                  final savedPath = await GraphImageExporter.saveJpgFile(
                    jpgBytes,
                    graphName ?? 'Grafo',
                  );
                  if (context.mounted) {
                    final message = kIsWeb
                        ? 'Descarga de imagen iniciada.'
                        : 'Imagen guardada exitosamente en:\n$savedPath';
                    AppToast.show(
                      context,
                      message,
                      icon: Icons.check_circle_rounded,
                      duration: const Duration(seconds: 4),
                    );
                    Navigator.of(ctx).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      'Error al guardar la imagen: $e',
                      icon: Icons.error_outline_rounded,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      duration: const Duration(seconds: 4),
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
