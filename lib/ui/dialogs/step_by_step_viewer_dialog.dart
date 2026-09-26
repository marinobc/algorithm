import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/graph_algorithm.dart';
import '../../algorithms/core/models/algorithm_step.dart';
import '../widgets/app_toast.dart';
import '../widgets/math_rich_text.dart';

/// Universal dialog widget that displays step-by-step mathematical breakdown
/// for any algorithm that provides a list of [AlgorithmStep] objects.
class StepByStepViewerDialog extends ConsumerStatefulWidget {
  final GraphAlgorithm algorithm;
  final List<AlgorithmStep> steps;

  const StepByStepViewerDialog({
    super.key,
    required this.algorithm,
    required this.steps,
  });

  static Future<void> show(
    BuildContext context,
    GraphAlgorithm algorithm,
    List<AlgorithmStep> steps,
  ) {
    if (steps.isEmpty) {
      AppToast.show(
        context,
        'No hay pasos matemáticos disponibles para la configuración actual.',
        icon: Icons.info_outline_rounded,
      );
      return Future.value();
    }
    return showDialog(
      context: context,
      builder: (_) =>
          StepByStepViewerDialog(algorithm: algorithm, steps: steps),
    );
  }

  @override
  ConsumerState<StepByStepViewerDialog> createState() =>
      _StepByStepViewerDialogState();
}

class _StepByStepViewerDialogState
    extends ConsumerState<StepByStepViewerDialog> {
  int _currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final step = widget.steps[_currentStepIndex];
    final totalSteps = widget.steps.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surfaceTint,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.algorithm.themeColor.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.algorithm.icon,
                      color: widget.algorithm.themeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matemática y Paso a Paso — ${widget.algorithm.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Paso ${step.stepNumber} de $totalSteps: ${step.title}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.algorithm.themeColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formula Banner (if present)
                      if (step.formulaLatex != null &&
                          step.formulaLatex!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.functions_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Fórmula / Ecuación Aplicada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              MathRichText(
                                text: step.formulaLatex!.contains('\$')
                                    ? step.formulaLatex!
                                    : '\$\$${step.formulaLatex!}\$\$',
                                baseStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Detailed Description
                      Text(
                        'Explicación Detallada:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MathRichText(
                        text: step.description,
                        baseStyle: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Chips (if any)
                      if (step.metrics.isNotEmpty) ...[
                        Text(
                          'Métricas del Paso:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: step.metrics.entries.map((entry) {
                            return Chip(
                              backgroundColor: colors.surfaceContainerHighest,
                              labelStyle: const TextStyle(fontSize: 12),
                              label: Text('${entry.key}: ${entry.value}'),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Matrix Snapshot (if present)
                      if (step.matrixSnapshot != null &&
                          step.matrixSnapshot!.isNotEmpty) ...[
                        Text(
                          'Estado Matricial en este Paso:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            defaultColumnWidth: const IntrinsicColumnWidth(),
                            border: TableBorder.all(
                              color: colors.outlineVariant,
                              width: 1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            children: step.matrixSnapshot!.map((row) {
                              return TableRow(
                                children: row.map((cell) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Center(
                                      child: Text(
                                        cell,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Navigation Stepper Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentStepIndex > 0
                        ? () => setState(() => _currentStepIndex--)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Anterior'),
                  ),
                  Text(
                    '${_currentStepIndex + 1} / $totalSteps',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _currentStepIndex < totalSteps - 1
                        ? () => setState(() => _currentStepIndex++)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
