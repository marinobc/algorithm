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
  late final PageController _pageController;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepSelected(int index) {
    setState(() {
      _currentStepIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalSteps = widget.steps.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surfaceTint,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
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
                          'Iteración ${_currentStepIndex + 1} de $totalSteps',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.algorithm.themeColor,
                          ),
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

              // Horizontal Step Chips Bar (Grouped by Iteration)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalSteps,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentStepIndex;
                    final step = widget.steps[index];
                    return ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: widget.algorithm.themeColor,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : colors.onSurfaceVariant,
                      ),
                      label: Text('Iteración ${index + 1}: ${step.title}'),
                      onSelected: (_) => _onStepSelected(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Horizontal Iteration Cards PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalSteps,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStepIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = widget.steps[index];
                    return _buildStepCard(
                      context,
                      colors,
                      step,
                      index + 1,
                      totalSteps,
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Navigation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentStepIndex > 0
                        ? () => _onStepSelected(_currentStepIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Anterior'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalSteps, (idx) {
                      final isCurrent = idx == _currentStepIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isCurrent ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? widget.algorithm.themeColor
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  FilledButton.icon(
                    onPressed: _currentStepIndex < totalSteps - 1
                        ? () => _onStepSelected(_currentStepIndex + 1)
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

  Widget _buildStepCard(
    BuildContext context,
    ColorScheme colors,
    AlgorithmStep step,
    int stepNum,
    int totalSteps,
  ) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: widget.algorithm.themeColor,
                    foregroundColor: Colors.white,
                    child: Text(
                      '$stepNum',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Formula Banner (if present)
              if (step.formulaLatex != null &&
                  step.formulaLatex!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
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
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Fórmula Aplicada',
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
                          fontSize: 13,
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
                'Explicación:',
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
                  fontSize: 13.5,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),

              // Metrics Chips (if any)
              if (step.metrics.isNotEmpty) ...[
                Text(
                  'Métricas:',
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
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 11.5),
                      label: Text('${entry.key}: ${entry.value}'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],

              // Matrix Snapshot (if present)
              if (step.matrixSnapshot != null &&
                  step.matrixSnapshot!.isNotEmpty) ...[
                Text(
                  'Estado Matricial:',
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
                              vertical: 7,
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
    );
  }
}
