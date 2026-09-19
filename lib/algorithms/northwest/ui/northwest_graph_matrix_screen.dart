import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../ui/widgets/algorithm_optimize_action.dart';
import '../domain/services/northwest_problem_extractor.dart';

/// Read-only bipartite cost matrix for the transport graph.
class NorthwestGraphMatrixScreen extends ConsumerWidget {
  const NorthwestGraphMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(grafoProvider);
    final origins = graph.nodos.values
        .where((node) => node.rol == NorthwestRoles.origin)
        .toList();
    final destinations = graph.nodos.values
        .where((node) => node.rol == NorthwestRoles.destination)
        .toList();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matriz de costos de transporte',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Orígenes (filas) × Destinos (columnas)',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: origins.isEmpty || destinations.isEmpty
            ? const _EmptyMatrixState()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: colors.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _TransportGrid(
                                graph: graph,
                                origins: origins,
                                destinations: destinations,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final didOptimize = await runActiveAlgorithm(
                            context,
                            ref,
                          );
                          if (didOptimize && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Optimizar transporte'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyMatrixState extends StatelessWidget {
  const _EmptyMatrixState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, size: 60, color: colors.primary),
            const SizedBox(height: 14),
            Text(
              'Aún no hay una matriz para mostrar',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega al menos un origen y un destino.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportGrid extends StatelessWidget {
  final Grafo graph;
  final List<Nodo> origins;
  final List<Nodo> destinations;

  const _TransportGrid({
    required this.graph,
    required this.origins,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows =
        List.generate(
          origins.length,
          (row) => DataRow(
            cells: [
              DataCell(
                Text(
                  origins[row].nombre ?? origins[row].id,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ...destinations.map(
                (destination) => DataCell(
                  Text(_connectionCost(origins[row].id, destination.id) ?? '—'),
                ),
              ),
              DataCell(Text(_formatOptional(origins[row].cantidad))),
            ],
          ),
        )..add(
          DataRow(
            color: WidgetStatePropertyAll(colors.primaryContainer),
            cells: [
              const DataCell(
                Text('Demanda', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              ...destinations.map(
                (destination) => DataCell(
                  Text(
                    _formatOptional(destination.cantidad),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const DataCell(Text('')),
            ],
          ),
        );

    return DataTable(
      headingRowColor: WidgetStatePropertyAll(colors.secondaryContainer),
      headingTextStyle: TextStyle(
        color: colors.onSecondaryContainer,
        fontWeight: FontWeight.w800,
      ),
      dataTextStyle: TextStyle(color: colors.onSurface),
      columns: [
        const DataColumn(label: Text('Origen')),
        ...destinations.map(
          (destination) =>
              DataColumn(label: Text(destination.nombre ?? destination.id)),
        ),
        const DataColumn(label: Text('Oferta')),
      ],
      rows: rows,
    );
  }

  String? _connectionCost(String originId, String destinationId) {
    for (final connection in graph.conexiones.values) {
      if (connection.nodoOrigenId != originId ||
          connection.nodoDestinoId != destinationId) {
        continue;
      }
      for (final attribute in connection.atributos) {
        if (attribute.atributoId == 'attr_valor') return attribute.valor;
      }
      return connection.atributos.isEmpty
          ? null
          : connection.atributos.first.valor;
    }
    return null;
  }

  String _formatOptional(double? value) => value == null ? '—' : _format(value);

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
