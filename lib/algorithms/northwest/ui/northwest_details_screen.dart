import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../domain/models/northwest_models.dart';
import '../providers/northwest_provider.dart';
import 'widgets/northwest_distribution_table.dart';
import 'widgets/northwest_step_by_step_widget.dart';

class NorthwestDetailsScreen extends ConsumerStatefulWidget {
  const NorthwestDetailsScreen({super.key});

  @override
  ConsumerState<NorthwestDetailsScreen> createState() =>
      _NorthwestDetailsScreenState();
}

class _NorthwestDetailsScreenState
    extends ConsumerState<NorthwestDetailsScreen> {
  bool _showSteps = false;

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(northwestResultProvider);
    final problem = ref.watch(northwestProblemProvider);
    final colors = Theme.of(context).colorScheme;
    final palette = NeumorphicPalette.of(context);

    if (result == null || problem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solución de transporte')),
        body: const Center(child: Text('No hay solución disponible.')),
      );
    }

    final isMinimization =
        problem.objective == TransportationObjective.minimize;
    return Scaffold(
      backgroundColor: palette.canvasBg,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerHigh,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.grid_view_rounded, color: colors.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Esquina Noroeste / MODI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color:
                          (isMinimization
                                  ? colors.primaryContainer
                                  : colors.tertiaryContainer)
                              .withValues(alpha: .85),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMinimization
                                  ? 'Costo Mínimo Total (Z)'
                                  : 'Beneficio Máximo Total (Z)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isMinimization
                                    ? colors.onPrimaryContainer
                                    : colors.onTertiaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Z = ${_formatNumber(result.objectiveValue)}',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isMinimization
                                    ? colors.onPrimaryContainer
                                    : colors.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Matriz de Distribución Óptima',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NorthwestDistributionTable.fromResult(
                    problem: problem,
                    result: result,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => setState(() {
                        _showSteps = !_showSteps;
                      }),
                      icon: Icon(
                        _showSteps
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.account_tree_outlined,
                      ),
                      label: Text(
                        _showSteps
                            ? 'Ocultar paso a paso'
                            : 'Mostrar paso a paso',
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
                            child: NorthwestStepByStepWidget(
                              problem: problem,
                              result: result,
                            ),
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
