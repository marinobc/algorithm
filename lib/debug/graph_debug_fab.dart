import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers/grafo_provider.dart';

/// A standalone debug FAB to export/copy the current graph data
/// (nodes, direction, connection values) to the clipboard.
///
/// Designed to be placed cleanly in UI stack overlays for quick testing,
/// and easily removed when no longer needed.
class GraphDebugFab extends ConsumerWidget {
  const GraphDebugFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      heroTag: 'debug_copy_graph_fab',
      tooltip: 'Copiar Datos del Grafo (Debug Test Data)',
      backgroundColor: Colors.deepOrangeAccent,
      foregroundColor: Colors.white,
      onPressed: () async {
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
          final orig = grafo.nodos[c.nodoOrigenId]?.nombre ?? c.nodoOrigenId;
          final dest = grafo.nodos[c.nodoDestinoId]?.nombre ?? c.nodoDestinoId;
          final attrStr = c.atributos.map((a) => '${a.atributoId}: ${a.valor}').join(', ');
          summary.writeln(
            '//   $orig ➔ $dest | Dir: ${c.direccion.name} | Attrs: [$attrStr]',
          );
        }
        summary.writeln('\n// JSON Payload for Grafo.fromJson:');
        summary.writeln(jsonString);

        final exportData = summary.toString();

        await Clipboard.setData(ClipboardData(text: exportData));

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grafo copiado al portapapeles (${grafo.nodos.length} nodos, ${grafo.conexiones.length} conexiones)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.deepOrange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: const Icon(Icons.bug_report_rounded, size: 18),
    );
  }
}
