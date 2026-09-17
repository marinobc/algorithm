import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers/grafo_provider.dart';
import '../domain/models/grafo.dart';
import '../ui/widgets/app_toast.dart';

/// A standalone debug FAB widget group containing export/copy and import/paste buttons
/// for quick node data testing and debugging.
class GraphDebugFab extends ConsumerWidget {
  const GraphDebugFab({super.key});

  void _showPasteDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.paste_rounded, color: Colors.deepOrangeAccent),
              SizedBox(width: 8),
              Text('Importar / Pegar Grafo', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pega abajo el texto o JSON exportado con el botón debug:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Pega aquí el contenido JSON del grafo...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Cargar Grafo'),
              onPressed: () {
                final input = controller.text.trim();
                if (input.isEmpty) return;

                try {
                  String jsonText = input;
                  // If user pasted the full debug export text containing "// JSON Payload for Grafo.fromJson:"
                  if (input.contains('{')) {
                    final jsonStartIndex = input.indexOf('{');
                    final jsonEndIndex = input.lastIndexOf('}');
                    if (jsonStartIndex != -1 &&
                        jsonEndIndex != -1 &&
                        jsonEndIndex > jsonStartIndex) {
                      jsonText = input.substring(
                        jsonStartIndex,
                        jsonEndIndex + 1,
                      );
                    }
                  }

                  final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
                  final nuevoGrafo = Grafo.fromJson(decoded);

                  ref.read(grafoProvider.notifier).cargarGrafo(nuevoGrafo);

                  Navigator.of(dialogContext).pop();
                  AppToast.show(
                    context,
                    'Grafo importado exitosamente (${nuevoGrafo.nodos.length} nodos, ${nuevoGrafo.conexiones.length} conexiones)',
                    icon: Icons.check_circle_rounded,
                  );
                } catch (e) {
                  AppToast.show(
                    context,
                    'Error al procesar el JSON del grafo: $e',
                    icon: Icons.error_outline_rounded,
                    backgroundColor: Colors.redAccent,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Paste/Import Debug FAB (placed on top of the bug button)
        FloatingActionButton.small(
          heroTag: 'debug_paste_graph_fab',
          tooltip: 'Pegar / Importar Datos del Grafo',
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          onPressed: () => _showPasteDialog(context, ref),
          child: const Icon(Icons.paste_rounded, size: 18),
        ),
        const SizedBox(height: 8),
        // Copy/Export Debug FAB (Bug button)
        FloatingActionButton.small(
          heroTag: 'debug_copy_graph_fab',
          tooltip: 'Copiar Datos del Grafo (Debug Test Data)',
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Colors.white,
          onPressed: () {
            final grafo = ref.read(grafoProvider);

            // Convert full graph data to formatted JSON
            const encoder = JsonEncoder.withIndent('  ');
            final jsonString = encoder.convert(grafo.toJson());

            // Human-readable summary for test setup
            final summary = StringBuffer();
            summary.writeln('// --- DEBUG GRAPH EXPORT ---');
            summary.writeln('// Nodes (${grafo.nodos.length}):');
            for (final nodo in grafo.nodos.values) {
              summary.writeln('//   ${nodo.nombre} (id: ${nodo.id})');
            }
            summary.writeln('// Connections (${grafo.conexiones.length}):');
            for (final c in grafo.conexiones.values) {
              final orig =
                  grafo.nodos[c.nodoOrigenId]?.nombre ?? c.nodoOrigenId;
              final dest =
                  grafo.nodos[c.nodoDestinoId]?.nombre ?? c.nodoDestinoId;
              final attrStr = c.atributos
                  .map((a) => '${a.atributoId}: ${a.valor}')
                  .join(', ');
              summary.writeln(
                '//   $orig -> $dest | Dir: ${c.direccion.name} | Attrs: [$attrStr]',
              );
            }
            summary.writeln('\n// JSON Payload for Grafo.fromJson:');
            summary.writeln(jsonString);

            final exportData = summary.toString();

            try {
              Clipboard.setData(ClipboardData(text: exportData));
              AppToast.show(
                context,
                'Grafo copiado al portapapeles (${grafo.nodos.length} nodos, ${grafo.conexiones.length} conexiones)',
                icon: Icons.bug_report,
              );
            } catch (_) {
              // Fallback dialog for browsers blocking direct clipboard access in WASM
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Datos del Grafo Exportados'),
                  content: SizedBox(
                    width: 400,
                    child: SelectableText(
                      exportData,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Icon(Icons.bug_report_rounded, size: 18),
        ),
      ],
    );
  }
}
