import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/widgets/base_algorithm_card.dart';
import '../providers/johnson_provider.dart';
import 'johnson_details_screen.dart';

/// Streamlined floating card overlay for Johnson's Algorithm (PERT/CPM).
/// Renders initial summary metrics and an action button to open full details screen.
class JohnsonAlgorithmCard extends ConsumerWidget {
  const JohnsonAlgorithmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(johnsonValidationProvider);
    final state = ref.watch(johnsonNotifierProvider);
    if (!state.isActive || !validation.isValid) return const SizedBox.shrink();

    final result = ref.watch(johnsonResultProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return BaseAlgorithmCard(
      title: 'Algoritmo de Johnson',
      icon: Icons.timeline_rounded,
      onClose: () {
        ref.read(johnsonNotifierProvider.notifier).setActive(false);
      },
      resultBanner: result != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duración del Proyecto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'T = ${result.totalDuration.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  if (result.criticalPathSequence.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ruta Crítica: ${result.criticalPathSequence.join(" ➔ ")}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            )
          : Text(
              'No se pudo obtener resultado para Johnson.',
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
                icon: const Icon(Icons.table_chart_outlined, size: 16),
                label: const Text(
                  'Ver Tabla de Tiempos y Detalles',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JohnsonDetailsScreen(),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }
}
