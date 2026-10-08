import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../ui/widgets/algorithm_optimize_action.dart';
import '../../core/algorithm_registry.dart';
import '../providers/assignment_provider.dart';
import 'widgets/bipartite_matrix_grid_table.dart';

/// Screen displaying the dedicated Bipartite Matrix (Origins x Destinations)
/// for the Assignment / Hungarian Algorithm.
class AssignmentBipartiteMatrixScreen extends ConsumerStatefulWidget {
  const AssignmentBipartiteMatrixScreen({super.key});

  @override
  ConsumerState<AssignmentBipartiteMatrixScreen> createState() =>
      _AssignmentBipartiteMatrixScreenState();
}

class _AssignmentBipartiteMatrixScreenState
    extends ConsumerState<AssignmentBipartiteMatrixScreen> {
  int? _selectedRowIndex;
  int? _selectedColumnIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grafo = ref.watch(grafoProvider);
    final validation = ref.watch(transportationValidationProvider);

    final origins = validation.origins;
    final destinations = validation.destinations;

    final activeAlgo = ref.watch(activeAlgorithmProvider);
    final isNorthwest = activeAlgo?.id == AlgorithmRegistry.northwestId;
    final title = isNorthwest
        ? 'Matriz de Esquina Noroeste'
        : 'Matriz de Costos de Asignación';
    final subtitle = isNorthwest
        ? 'Bipartita: Orígenes (Filas) × Destinos (Columnas) con Oferta, Demanda y Pesos'
        : 'Bipartita: Orígenes (Filas) × Destinos (Columnas)';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: !validation.isValid
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Grafo de Asignación incompleto o inválido',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        validation.errorMessage ?? 'Configure nodos de origen y destino conectados para ver la matriz de asignación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Main Matrix Card
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: BipartiteMatrixGridTable(
                                    grafo: grafo,
                                    origins: origins,
                                    destinations: destinations,
                                    isNorthwest: isNorthwest,
                                    selectedRowIndex: _selectedRowIndex,
                                    selectedColumnIndex: _selectedColumnIndex,
                                    onSelectionChanged: (row, col) {
                                      setState(() {
                                        _selectedRowIndex = row;
                                        _selectedColumnIndex = col;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width > 600
                            ? 240
                            : double.infinity,
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
                          label: const Text('Optimizar asignación'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
