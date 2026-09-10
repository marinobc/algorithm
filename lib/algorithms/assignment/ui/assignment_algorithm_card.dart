import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/widgets/base_algorithm_card.dart';
import '../domain/models/assignment_models.dart';
import '../providers/assignment_provider.dart';
import 'assignment_details_screen.dart';

/// Streamlined floating card overlay for the Assignment (Hungarian) Algorithm.
/// Renders initial summary metrics and an action button to open full details screen.
class AssignmentAlgorithmCard extends ConsumerWidget {
  const AssignmentAlgorithmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(transportationValidationProvider);
    final state = ref.watch(transportationNotifierProvider);
    if (!state.isActive || !validation.isValid) return const SizedBox.shrink();

    final result = ref.watch(transportationResultProvider);
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMin
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    'Z = ${result.totalCost.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                    style: TextStyle(
                      fontSize: 15,
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
      body: result != null
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text(
                  'Ver Detalles y Matriz Completa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AssignmentDetailsScreen(),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }
}
