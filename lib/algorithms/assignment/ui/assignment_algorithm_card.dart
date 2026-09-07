import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/widgets/base_algorithm_card.dart';
import '../domain/models/assignment_models.dart';
import '../providers/assignment_provider.dart';

/// Domain-specific floating card for the Assignment (Hungarian) Algorithm.
/// Uses [BaseAlgorithmCard] for a standardized, modular UI appearance.
class AssignmentAlgorithmCard extends ConsumerWidget {
  const AssignmentAlgorithmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(transportationValidationProvider);
    final state = ref.watch(transportationNotifierProvider);
    if (!state.isActive || !validation.isValid) return const SizedBox.shrink();

    final result = ref.watch(transportationResultProvider);
    final problem = ref.watch(transportationProblemDataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final currentGoal = state.optimizationGoal;
    final isMin = currentGoal == OptimizationGoal.minimize;

    return BaseAlgorithmCard(
      title: 'Algoritmo de Asignación',
      icon: Icons.alt_route_rounded,
      onClose: () {
        ref.read(transportationNotifierProvider.notifier).setActive(false);
      },
      headerActions: [
        // Min / Max Segmented Choice
        SegmentedButton<OptimizationGoal>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          segments: const [
            ButtonSegment<OptimizationGoal>(
              value: OptimizationGoal.minimize,
              label: Text(
                'Min',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              icon: Icon(Icons.trending_down, size: 14),
            ),
            ButtonSegment<OptimizationGoal>(
              value: OptimizationGoal.maximize,
              label: Text(
                'Max',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              icon: Icon(Icons.trending_up, size: 14),
            ),
          ],
          selected: {currentGoal},
          onSelectionChanged: (newSelection) {
            ref
                .read(transportationNotifierProvider.notifier)
                .setGoal(newSelection.first);
          },
        ),
      ],
      resultBanner: result != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMin
                    ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                    : colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMin ? 'Costo Mínimo (Z)' : 'Ganancia Máxima (Z)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isMin
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    'Z = ${result.totalCost.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isMin
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            )
          : Text(
              'No se pudo obtener resultado.',
              style: TextStyle(fontSize: 12, color: colorScheme.error),
            ),
      body: (result != null && problem != null)
          ? Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _buildAssignmentChips(result, problem, colorScheme),
            )
          : null,
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
              : '$origLabel ➔ $destLabel (${costVal.toStringAsFixed(0)})';

          widgets.add(
            RawChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              label: Text(
                labelText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFicticio
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              backgroundColor: isFicticio
                  ? colorScheme.surfaceContainer
                  : colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isFicticio
                      ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant,
                  width: 0.5,
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
