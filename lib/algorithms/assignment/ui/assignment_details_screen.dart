import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../domain/models/assignment_models.dart';
import '../providers/assignment_provider.dart';
import 'widgets/assignment_allocation_matrix_table.dart';
import 'widgets/assignment_step_by_step_widget.dart';

class AssignmentDetailsScreen extends ConsumerStatefulWidget {
  const AssignmentDetailsScreen({super.key});

  @override
  ConsumerState<AssignmentDetailsScreen> createState() =>
      _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState
    extends ConsumerState<AssignmentDetailsScreen> {
  bool _showSteps = false;

  @override
  Widget build(BuildContext context) {
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

                  // Allocation Matrix Table & Chips
                  AssignmentAllocationMatrixTable(
                    result: result,
                    problem: problem,
                  ),
                  const SizedBox(height: 24),

                  // Step-by-Step Toggle Button inside Solution View
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showSteps = !_showSteps;
                        });
                      },
                      icon: Icon(
                        _showSteps
                            ? Icons.expand_less_rounded
                            : Icons.auto_awesome_rounded,
                      ),
                      label: Text(
                        _showSteps
                            ? 'Ocultar paso a paso matemático'
                            : 'Mostrar paso a paso matemático (Método Húngaro)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    child: _showSteps
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: AssignmentStepByStepWidget(result: result),
                          )
                        : const SizedBox.shrink(),
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
}
