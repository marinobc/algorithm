import 'package:flutter/material.dart';

import '../../../../ui/widgets/math_rich_text.dart';
import '../../domain/models/assignment_models.dart';

class AssignmentStepByStepWidget extends StatefulWidget {
  final TransportationResult result;

  const AssignmentStepByStepWidget({super.key, required this.result});

  @override
  State<AssignmentStepByStepWidget> createState() =>
      _AssignmentStepByStepWidgetState();
}

class _AssignmentStepByStepWidgetState
    extends State<AssignmentStepByStepWidget> {
  late final PageController _pageController;
  int _currentStep = 0;

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

  void _goToStep(int index) {
    setState(() {
      _currentStep = index;
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

    final reductionSteps = widget.result.steps
        .where(
          (s) =>
              s.rowVectorAlpha != null ||
              s.colVectorBeta != null ||
              s.stepNumber <= 2,
        )
        .toList();
    final adjustmentSteps = widget.result.steps
        .where(
          (s) =>
              s.thetaValue != null ||
              s.coveredRows != null ||
              (s.stepNumber > 2 && s != widget.result.steps.last),
        )
        .toList();
    final finalSteps = [widget.result.steps.last];

    final iterationCards = <Map<String, dynamic>>[
      {
        'title': 'Iteración 1: Reducción Inicial de Matriz',
        'subtitle': 'Reducción por filas (α) y por columnas (β)',
        'steps': reductionSteps.isEmpty ? widget.result.steps : reductionSteps,
      },
      if (adjustmentSteps.isNotEmpty)
        {
          'title': 'Iteración 2: Cobertura de Ceros y Ajuste θ',
          'subtitle': 'Líneas mínimas de cobertura y reajuste de matriz',
          'steps': adjustmentSteps,
        },
      {
        'title': 'Iteración Final: Asignaciones Óptimas',
        'subtitle': 'Distribución final de costo mínimo / beneficio máximo',
        'steps': finalSteps,
      },
    ];

    final totalCards = iterationCards.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolución Paso a Paso — Método Húngaro',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Cada tarjeta contiene la resolución completa de una iteración en hoja única:',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalCards,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == _currentStep;
              final cardInfo = iterationCards[index];
              return ChoiceChip(
                selected: isSelected,
                showCheckmark: false,
                selectedColor: colors.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                ),
                label: Text(cardInfo['title'] as String),
                onSelected: (_) => _goToStep(index),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 540,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalCards,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            itemBuilder: (context, index) {
              final cardInfo = iterationCards[index];
              final stepsList = cardInfo['steps'] as List<StepExplanation>;
              return _buildNotebookIterationCard(
                colors,
                cardInfo['title'] as String,
                cardInfo['subtitle'] as String,
                stepsList,
                index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotebookIterationCard(
    ColorScheme colors,
    String title,
    String subtitle,
    List<StepExplanation> steps,
    int cardNum,
  ) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      '$cardNum',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...steps.map((step) => _buildStepSection(colors, step)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSection(ColorScheme colors, StepExplanation step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MathRichText(
            text: '• ${step.title}',
            baseStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          MathRichText(
            text: step.description,
            baseStyle: TextStyle(
              fontSize: 12.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (step.formulaLatex != null && step.formulaLatex!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: MathRichText(
                text: step.formulaLatex!.contains('\$')
                    ? step.formulaLatex!
                    : '\$\$${step.formulaLatex!}\$\$',
                baseStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ],
          if (step.rowVectorAlpha != null &&
              step.rowVectorAlpha!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  elevation: 0,
                  backgroundColor: colors.surfaceContainerHighest,
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  label: MathRichText(
                    text:
                        'Vector \$\\boldsymbol{\\alpha} = [${step.rowVectorAlpha!.map((e) => e.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')).join(', ')}]\$',
                    baseStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (step.colVectorBeta != null &&
                    step.colVectorBeta!.isNotEmpty)
                  Chip(
                    elevation: 0,
                    backgroundColor: colors.surfaceContainerHighest,
                    side: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    label: MathRichText(
                      text:
                          'Vector \$\\boldsymbol{\\beta} = [${step.colVectorBeta!.map((e) => e.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')).join(', ')}]\$',
                      baseStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (step.thetaValue != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  elevation: 0,
                  backgroundColor: colors.tertiaryContainer,
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  label: MathRichText(
                    text:
                        'Filas Cubiertas: \$R_{cov} = \\{${step.coveredRows?.join(', ') ?? ''}\\}\$',
                    baseStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                ),
                Chip(
                  elevation: 0,
                  backgroundColor: colors.tertiaryContainer,
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  label: MathRichText(
                    text:
                        'Cols Cubiertas: \$C_{cov} = \\{${step.coveredCols?.join(', ') ?? ''}\\}\$',
                    baseStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                ),
                Chip(
                  elevation: 0,
                  backgroundColor: colors.primaryContainer,
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                  label: MathRichText(
                    text:
                        '\$\\theta = ${step.thetaValue!.toStringAsFixed(2)}\$',
                    baseStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (step.alphaMatrix != null || step.betaMatrix != null) ...[
            const SizedBox(height: 10),
            MathRichText(
              text: step.alphaMatrix != null
                  ? 'Matriz Alpha Generada (\$A_{\\alpha}\$):'
                  : 'Matriz Beta Generada (\$B_{\\beta}\$):',
              baseStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.secondary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  children: (step.alphaMatrix ?? step.betaMatrix!).map((row) {
                    return TableRow(
                      children: row.map((val) {
                        final textVal = val
                            .toStringAsFixed(1)
                            .replaceAll(RegExp(r'\.0$'), '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Center(
                            child: Text(
                              textVal,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.secondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          if (step.currentAllocations != null) ...[
            const SizedBox(height: 10),
            Text(
              'Matriz Resultante del Paso:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  children: step.currentAllocations!.map((row) {
                    return TableRow(
                      children: row.map((val) {
                        final textVal = val
                            .toStringAsFixed(1)
                            .replaceAll(RegExp(r'\.0$'), '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Center(
                            child: Text(
                              textVal,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: val == 0
                                    ? FontWeight.w900
                                    : FontWeight.normal,
                                color: val == 0
                                    ? colors.primary
                                    : colors.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
