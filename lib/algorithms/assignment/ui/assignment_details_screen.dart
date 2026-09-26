import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/math_rich_text.dart';
import '../domain/models/assignment_models.dart';
import '../providers/assignment_provider.dart';

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
                  Align(
                    alignment: Alignment.center,
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
                            child: _AssignmentStepByStep(result: result),
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

  Widget _buildAllocationMatrixTable(
    TransportationResult result,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Origen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  ...result.destinationLabels.map((dest) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Text(
                          dest,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              ...List.generate(result.originLabels.length, (i) {
                final origName = result.originLabels[i];
                return TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        origName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ...List.generate(result.destinationLabels.length, (j) {
                      final alloc = result.allocationMatrix[i][j];
                      final isAssigned = alloc > 0;
                      final cost = result.costMatrix[i][j];
                      final costText = cost.isFinite && cost < 1e5
                          ? cost
                                .toStringAsFixed(1)
                                .replaceAll(RegExp(r'\.0$'), '')
                          : '∞';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                        color: isAssigned
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.55,
                              )
                            : colorScheme.surfaceContainerLow.withValues(
                                alpha: 0.3,
                              ),
                        child: Text(
                          isAssigned ? '1 (c=$costText)' : '0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isAssigned
                                ? FontWeight.w800
                                : FontWeight.normal,
                            color: isAssigned
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAssignmentChips(
    TransportationResult result,
    TransportationProblemData problem,
    ColorScheme colorScheme,
  ) {
    final chips = <Widget>[];

    for (int i = 0; i < result.allocationMatrix.length; i++) {
      for (int j = 0; j < result.allocationMatrix[i].length; j++) {
        if (result.allocationMatrix[i][j] > 0) {
          // Exclude dummy balance origins or destinations from real solution pairs chips
          if (i >= problem.origins.length || j >= problem.destinations.length) {
            continue;
          }
          final origLabel = result.originLabels[i];
          final destLabel = result.destinationLabels[j];
          final cost = result.costMatrix[i][j];
          final displayCost = cost.isFinite && cost < 1e5
              ? cost.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
              : '0';

          chips.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.check, size: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$origLabel ➔ $destLabel (Costo: $displayCost)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return chips;
  }
}

class _AssignmentStepByStep extends StatelessWidget {
  final TransportationResult result;

  const _AssignmentStepByStep({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          'Cada etapa reduce la matriz de costos y aplica cubrimientos de ceros para encontrar la asignación óptima.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 14),
        ...List.generate(result.steps.length, (index) {
          final step = result.steps[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: ExpansionTile(
                initiallyExpanded:
                    index == 0 || index == result.steps.length - 1,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: CircleAvatar(
                  radius: 15,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: MathRichText(
                  text: step.title,
                  baseStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: MathRichText(
                  text: step.description,
                  baseStyle: const TextStyle(fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const SizedBox(height: 8),
                  if (step.formulaLatex != null &&
                      step.formulaLatex!.isNotEmpty) ...[
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
                    const SizedBox(height: 10),
                  ],
                  if (step.rowVectorAlpha != null &&
                      step.rowVectorAlpha!.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
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
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            backgroundColor: colors.surfaceContainerHighest,
                            side: BorderSide(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
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
                    const SizedBox(height: 8),
                  ],
                  if (step.thetaValue != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
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
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
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
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
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
                    const SizedBox(height: 8),
                  ],
                  if (step.alphaMatrix != null || step.betaMatrix != null) ...[
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
                              color: colors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              width: 0.8,
                            ),
                          ),
                          children: (step.alphaMatrix ?? step.betaMatrix!).map((
                            row,
                          ) {
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
                    const SizedBox(height: 12),
                  ],
                  if (step.currentAllocations != null) ...[
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
                              color: colors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
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
            ),
          );
        }),
      ],
    );
  }
}
