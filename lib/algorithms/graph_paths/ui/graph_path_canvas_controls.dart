import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../../../domain/models/direccion.dart';
import '../../../domain/models/grafo.dart';
import '../providers/graph_path_run_provider.dart';
import 'graph_path_colors.dart';

/// Uses the same small canvas status area as Johnson and Assignment.
class GraphPathCanvasControls extends ConsumerWidget {
  final bool kruskal;
  const GraphPathCanvasControls({super.key, required this.kruskal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(grafoProvider);
    final run = ref.watch(graphPathRunProvider);
    final colors = Theme.of(context).colorScheme;
    final accent = kruskal
        ? GraphPathColors.kruskalAccent
        : GraphPathColors.dijkstraAccent;
    final incompatible =
        kruskal &&
        graph.conexiones.values.any(
          (edge) => edge.direccion != Direccion.ninguna,
        );

    String status;
    if (graph.nodos.isEmpty) {
      status = 'Haz clic para crear vértices; arrastra entre ellos para conectarlos.';
    } else if (kruskal) {
      final components = _componentCount(graph);
      status = incompatible
          ? 'Hay aristas dirigidas: edítalas a «No dirigida».'
          : '${graph.nodos.length} vértices · ${graph.conexiones.length} aristas · '
                '${components == 1 ? 'conectado' : '$components componentes · bosque'}';
    } else {
      final source = graph.nodos[run.sourceId]?.nombre ?? '—';
      final target = graph.nodos[run.targetId]?.nombre ?? '—';
      final selection = run.sourceIsManual || run.targetIsManual
          ? 'selección personalizada'
          : run.inferredFromTopology
          ? 'detectados por grado'
          : 'predeterminados por creación';
      status = 'Origen: $source → Destino: $target · $selection';
    }

    final selectedLabel = switch (run.mode) {
      GraphPathMode.dijkstra => 'Camino mínimo',
      GraphPathMode.longestSimple => 'Camino máximo simple',
      GraphPathMode.kruskalMinimum => 'Árbol mínimo',
      GraphPathMode.kruskalMaximum => 'Árbol máximo',
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: min(540, MediaQuery.sizeOf(context).width - 28),
      ),
      child: Material(
        color: colors.surfaceContainerHigh.withValues(alpha: .97),
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: .35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    kruskal ? Icons.account_tree_outlined : Icons.route_rounded,
                    color: accent,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    kruskal ? 'Kruskal' : 'Dijkstra',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<GraphPathMode>(
                    tooltip:
                        'Elegir método de ${kruskal ? 'Kruskal' : 'Dijkstra'}',
                    onSelected: (mode) =>
                        ref.read(graphPathRunProvider.notifier).setMode(mode),
                    itemBuilder: (_) => kruskal
                        ? const [
                            PopupMenuItem(
                              value: GraphPathMode.kruskalMinimum,
                              child: Text('Árbol mínimo'),
                            ),
                            PopupMenuItem(
                              value: GraphPathMode.kruskalMaximum,
                              child: Text('Árbol máximo'),
                            ),
                          ]
                        : const [
                            PopupMenuItem(
                              value: GraphPathMode.dijkstra,
                              child: Text('Camino mínimo · Dijkstra'),
                            ),
                            PopupMenuItem(
                              value: GraphPathMode.longestSimple,
                              child: Text(
                                'Camino máximo simple · método distinto',
                              ),
                            ),
                          ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: incompatible ? colors.error : colors.onSurfaceVariant,
                ),
              ),
              if (!kruskal && graph.nodos.isNotEmpty)
                Text(
                  'Cambia los extremos desde el menú de cada nodo.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _componentCount(Grafo graph) {
    final adjacency = <String, Set<String>>{
      for (final id in graph.nodos.keys) id: <String>{},
    };
    for (final edge in graph.conexiones.values) {
      adjacency[edge.nodoOrigenId]?.add(edge.nodoDestinoId);
      adjacency[edge.nodoDestinoId]?.add(edge.nodoOrigenId);
    }
    final visited = <String>{};
    var count = 0;
    for (final id in graph.nodos.keys) {
      if (!visited.add(id)) continue;
      count++;
      final stack = <String>[id];
      while (stack.isNotEmpty) {
        for (final neighbor in adjacency[stack.removeLast()] ?? <String>{}) {
          if (visited.add(neighbor)) stack.add(neighbor);
        }
      }
    }
    return count;
  }
}
