import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../domain/models/assignment_models.dart';
import '../providers/assignment_provider.dart';

class AssignmentDetailsScreen extends ConsumerWidget {
  const AssignmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(transportationResultProvider);
    final problem = ref.watch(transportationProblemDataProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = NeumorphicPalette.of(context);

    if (result == null || problem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solución de Asignación')),
        body: const Center(
          child: Text('No hay solución disponible para el grafo actual.'),
        ),
      );
    }

    final isMin = result.goal == OptimizationGoal.minimize;

    return Scaffold(
      backgroundColor: palette.canvasBg,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.alt_route_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Asignación (${isMin ? "Minimización" : "Maximización"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Banner
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: isMin
                        ? colorScheme.primaryContainer.withValues(alpha: 0.85)
                        : colorScheme.tertiaryContainer.withValues(alpha: 0.85),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMin
                                        ? 'Costo Mínimo Total (Z)'
                                        : 'Ganancia Máxima Total (Z)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isMin
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Z = ${result.totalCost.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: isMin
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  result.wasBalancedWithDummy
                                      ? 'Balanceado con 0'
                                      : 'Grafo Balanceado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Allocation Matrix Section
                  Text(
                    'Matriz Final de Asignaciones Óptimas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildAllocationMatrixTable(result, colorScheme),
                  ),
                  const SizedBox(height: 24),

                  // Detailed Assigned Pairs Section
                  Text(
                    'Desglose de Pares Asignados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _buildAssignmentChips(
                      result,
                      problem,
                      colorScheme,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationMatrixTable(
    TransportationResult result,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 16,
        headingRowHeight: 42,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHigh,
        ),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: colorScheme.primary,
        ),
        columns: [
          const DataColumn(label: Text('Origen / Destino')),
          ...result.destinationLabels.map(
            (label) => DataColumn(label: Text(label)),
          ),
        ],
        rows: List.generate(result.originLabels.length, (i) {
          final origName = result.originLabels[i];
          return DataRow(
            cells: [
              DataCell(
                Text(
                  origName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              ...List.generate(result.destinationLabels.length, (j) {
                final alloc = result.allocationMatrix[i][j];
                final isAllocated = alloc > 0;
                final cost = result.costMatrix[i][j];
                final costStr = cost.isFinite ? cost.toStringAsFixed(0) : '-';

                return DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAllocated
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAllocated ? 'Asignado (Costo: $costStr)' : '-',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isAllocated
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAllocated
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _buildAssignmentChips(
    TransportationResult result,
    TransportationProblemData problem,
    ColorScheme colorScheme,
  ) {
    final widgets = <Widget>[];

    for (int i = 0; i < result.allocationMatrix.length; i++) {
      for (int j = 0; j < result.allocationMatrix[i].length; j++) {
        if (result.allocationMatrix[i][j] > 0) {
          final isFicticio =
              i >= problem.origins.length || j >= problem.destinations.length;
          final origLabel = i < problem.origins.length
              ? problem.origins[i].nombre
              : 'Descartado';
          final destLabel = j < problem.destinations.length
              ? problem.destinations[j].nombre
              : 'Descartado';
          final costVal =
              (i < problem.costMatrix.length &&
                  j < problem.costMatrix[i].length)
              ? problem.costMatrix[i][j]
              : 0.0;

          final labelText = isFicticio
              ? '$origLabel ➔ $destLabel'
              : '$origLabel ➔ $destLabel (Costo: ${costVal.toStringAsFixed(0)})';

          widgets.add(
            RawChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              avatar: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: isFicticio ? colorScheme.outline : colorScheme.primary,
              ),
              label: Text(
                labelText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFicticio
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : colorScheme.onSurface,
                ),
              ),
              backgroundColor: isFicticio
                  ? colorScheme.surfaceContainer
                  : colorScheme.primaryContainer.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isFicticio
                      ? colorScheme.outlineVariant
                      : colorScheme.primary.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }
}
