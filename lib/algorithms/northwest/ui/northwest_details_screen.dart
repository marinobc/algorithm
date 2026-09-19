import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../domain/models/northwest_models.dart';
import '../providers/northwest_provider.dart';

class NorthwestDetailsScreen extends ConsumerStatefulWidget {
  const NorthwestDetailsScreen({super.key});

  @override
  ConsumerState<NorthwestDetailsScreen> createState() =>
      _NorthwestDetailsScreenState();
}

class _NorthwestDetailsScreenState
    extends ConsumerState<NorthwestDetailsScreen> {
  bool _showSteps = false;

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
                  Align(
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          horizontalMargin: 16,
                          headingRowHeight: 42,
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 44,
                          headingRowColor: WidgetStatePropertyAll(
                            colors.surfaceContainerHigh,
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colors.primary,
                          ),
                          columns: [
                            const DataColumn(label: Text('Origen')),
                            ...List.generate(problem.destinationNames.length, (
                              col,
                            ) {
                              final name = problem.destinationNames[col];
                              final id = col < problem.destinationIds.length
                                  ? problem.destinationIds[col]
                                  : '';
                              final isFictitious =
                                  id == 'nw_dummy_destination' ||
                                  name == 'Ficticio' ||
                                  name.startsWith('Ficticio ');
                              return DataColumn(
                                label: Text(
                                  name,
                                  style: TextStyle(
                                    color: isFictitious
                                        ? colors.onSurfaceVariant.withValues(
                                            alpha: 0.5,
                                          )
                                        : colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Disponible',
                                  style: TextStyle(
                                    color: colors.onSecondaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: [
                            ...List.generate(problem.rowCount, (row) {
                              final origName = problem.originNames[row];
                              final origId = row < problem.originIds.length
                                  ? problem.originIds[row]
                                  : '';
                              final isOriginFictitious =
                                  origId == 'nw_dummy_origin' ||
                                  origName == 'Ficticio' ||
                                  origName.startsWith('Ficticio ');
                              return DataRow(
                                color: isOriginFictitious
                                    ? WidgetStatePropertyAll(
                                        colors.surfaceContainerHighest
                                            .withValues(alpha: 0.35),
                                      )
                                    : null,
                                cells: [
                                  DataCell(
                                    Text(
                                      origName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isOriginFictitious
                                            ? colors.onSurfaceVariant
                                                  .withValues(alpha: 0.5)
                                            : colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(
                                    problem.destinationNames.length,
                                    (col) {
                                      final destName =
                                          problem.destinationNames[col];
                                      final destId =
                                          col < problem.destinationIds.length
                                          ? problem.destinationIds[col]
                                          : '';
                                      final isDestFictitious =
                                          destId == 'nw_dummy_destination' ||
                                          destName == 'Ficticio' ||
                                          destName.startsWith('Ficticio ');
                                      final isCellFictitious =
                                          isOriginFictitious ||
                                          isDestFictitious;
                                      final value =
                                          result.allocations[row][col];
                                      return DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: isCellFictitious
                                              ? BoxDecoration(
                                                  color: colors
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                )
                                              : null,
                                          child: Text(
                                            _formatNumber(value),
                                            style: TextStyle(
                                              color: isCellFictitious
                                                  ? colors.onSurfaceVariant
                                                        .withValues(alpha: 0.45)
                                                  : colors.onSurface,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOriginFictitious
                                            ? colors.surfaceContainerHighest
                                                  .withValues(alpha: 0.6)
                                            : colors.secondaryContainer
                                                  .withValues(alpha: .62),
                                        borderRadius: BorderRadius.circular(6),
                                        border: isOriginFictitious
                                            ? null
                                            : Border.all(
                                                color: colors.secondary
                                                    .withValues(alpha: .45),
                                              ),
                                      ),
                                      child: Text(
                                        _formatNumber(problem.supplies[row]),
                                        style: TextStyle(
                                          color: isOriginFictitious
                                              ? colors.onSurfaceVariant
                                                    .withValues(alpha: 0.45)
                                              : colors.onSecondaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Demanda',
                                      style: TextStyle(
                                        color: colors.onTertiaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                ...List.generate(
                                  problem.destinationNames.length,
                                  (col) {
                                    final destName =
                                        problem.destinationNames[col];
                                    final destId =
                                        col < problem.destinationIds.length
                                        ? problem.destinationIds[col]
                                        : '';
                                    final isDestFictitious =
                                        destId == 'nw_dummy_destination' ||
                                        destName == 'Ficticio' ||
                                        destName.startsWith('Ficticio ');
                                    return DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDestFictitious
                                              ? colors.surfaceContainerHighest
                                                    .withValues(alpha: 0.6)
                                              : colors.tertiaryContainer
                                                    .withValues(alpha: .62),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: isDestFictitious
                                              ? null
                                              : Border.all(
                                                  color: colors.tertiary
                                                      .withValues(alpha: .45),
                                                ),
                                        ),
                                        child: Text(
                                          _formatNumber(problem.demands[col]),
                                          style: TextStyle(
                                            color: isDestFictitious
                                                ? colors.onSurfaceVariant
                                                      .withValues(alpha: 0.45)
                                                : colors.onTertiaryContainer,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const DataCell(Text('')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
                            child: _NorthwestStepByStep(
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

class _NorthwestStepByStep extends StatelessWidget {
  final TransportationInput problem;
  final NorthwestResult result;

  const _NorthwestStepByStep({required this.problem, required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolución paso a paso',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Esquina Noroeste construye la solución inicial y MODI la mejora hasta alcanzar el valor óptimo.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        _StepPanel(
          number: 1,
          title: 'Solución inicial por Esquina Noroeste',
          subtitle:
              'Z inicial = ${_formatNumber(result.initialObjectiveValue)}',
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se comienza en la esquina superior izquierda y en cada casilla se asigna el menor valor entre la disponibilidad y la demanda restantes.',
              ),
              const SizedBox(height: 12),
              _AllocationTable(
                problem: problem,
                allocations: result.initialAllocations,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(result.iterations.length, (index) {
          final iteration = result.iterations[index];
          final entering = iteration.enteringCell;
          final isOptimal = iteration.isOptimal;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == result.iterations.length - 1 ? 0 : 10,
            ),
            child: _StepPanel(
              number: index + 2,
              title: isOptimal
                  ? 'Comprobación de optimalidad'
                  : 'Iteración MODI ${iteration.number}',
              subtitle: isOptimal
                  ? 'No existen diferencias que mejoren la solución.'
                  : 'Entra ${_cellName(problem, entering)} · α = ${_formatNumber(iteration.alpha!)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PotentialSummary(iteration: iteration),
                  const SizedBox(height: 16),
                  _LabeledMatrix(
                    title: 'Matriz G = u + v',
                    problem: problem,
                    values: iteration.opportunityMatrix,
                  ),
                  const SizedBox(height: 16),
                  _LabeledMatrix(
                    title: 'Matriz Delta = C − G',
                    problem: problem,
                    values: iteration.deltas,
                    highlightedCell: entering,
                  ),
                  if (!isOptimal) ...[
                    const SizedBox(height: 16),
                    Text(
                      problem.objective == TransportationObjective.minimize
                          ? 'Se elige la diferencia negativa de mayor magnitud: ${_cellName(problem, entering)}.'
                          : 'Se elige la diferencia positiva más alta: ${_cellName(problem, entering)}.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _CircuitView(problem: problem, iteration: iteration),
                    const SizedBox(height: 16),
                    Text(
                      'Nueva distribución · Z = ${_formatNumber(iteration.objectiveValue)}',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AllocationTable(
                      problem: problem,
                      allocations: iteration.allocations,
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${problem.objective == TransportationObjective.minimize ? "Todas las diferencias no básicas son mayores o iguales a cero" : "Todas las diferencias no básicas son menores o iguales a cero"}. La solución es óptima con Z = ${_formatNumber(iteration.objectiveValue)}.',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
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

class _StepPanel extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const _StepPanel({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [const Divider(), const SizedBox(height: 8), child],
      ),
    );
  }
}

class _PotentialSummary extends StatelessWidget {
  final ModiIteration iteration;

  const _PotentialSummary({required this.iteration});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ValueChip(
          label: 'u',
          value: iteration.rowPotentials.map(_formatNumber).join(', '),
          color: colors.secondaryContainer,
          foreground: colors.onSecondaryContainer,
        ),
        _ValueChip(
          label: 'v',
          value: iteration.columnPotentials.map(_formatNumber).join(', '),
          color: colors.tertiaryContainer,
          foreground: colors.onTertiaryContainer,
        ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color foreground;

  const _ValueChip({
    required this.label,
    required this.value,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label = [$value]',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabeledMatrix extends StatelessWidget {
  final String title;
  final TransportationInput problem;
  final List<List<double>> values;
  final TransportCell? highlightedCell;

  const _LabeledMatrix({
    required this.title,
    required this.problem,
    required this.values,
    this.highlightedCell,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(72),
                border: TableBorder.all(color: colors.outlineVariant),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                    ),
                    children: [
                      const _MatrixCell(text: ''),
                      ...problem.destinationNames.map(
                        (name) => _MatrixCell(text: name, isHeader: true),
                      ),
                    ],
                  ),
                  ...List.generate(
                    values.length,
                    (row) => TableRow(
                      children: [
                        _MatrixCell(
                          text: problem.originNames[row],
                          isHeader: true,
                        ),
                        ...List.generate(
                          values[row].length,
                          (column) => _MatrixCell(
                            text: _formatNumber(values[row][column]),
                            highlighted:
                                highlightedCell?.row == row &&
                                highlightedCell?.column == column,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool highlighted;

  const _MatrixCell({
    required this.text,
    this.isHeader = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      alignment: Alignment.center,
      color: highlighted ? colors.primaryContainer : null,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader || highlighted
              ? FontWeight.w800
              : FontWeight.w500,
          color: highlighted ? colors.onPrimaryContainer : null,
        ),
      ),
    );
  }
}

class _CircuitView extends StatelessWidget {
  final TransportationInput problem;
  final ModiIteration iteration;

  const _CircuitView({required this.problem, required this.iteration});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Circuito cerrado · α = ${_formatNumber(iteration.alpha!)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(iteration.circuit.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: colors.onSurfaceVariant,
              );
            }
            final circuitIndex = index ~/ 2;
            final cell = iteration.circuit[circuitIndex];
            final positive = circuitIndex.isEven;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: positive
                    ? colors.primaryContainer
                    : colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_cellName(problem, cell)} ${positive ? "+" : "−"}',
                style: TextStyle(
                  color: positive
                      ? colors.onPrimaryContainer
                      : colors.onErrorContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AllocationTable extends StatelessWidget {
  final TransportationInput problem;
  final List<List<double>> allocations;

  const _AllocationTable({required this.problem, required this.allocations});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            horizontalMargin: 12,
            headingRowHeight: 38,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            headingRowColor: WidgetStatePropertyAll(
              colors.surfaceContainerHigh,
            ),
            columns: [
              const DataColumn(label: Text('Origen')),
              ...List.generate(problem.destinationNames.length, (col) {
                final name = problem.destinationNames[col];
                final id = col < problem.destinationIds.length
                    ? problem.destinationIds[col]
                    : '';
                final isFictitious =
                    id == 'nw_dummy_destination' ||
                    name == 'Ficticio' ||
                    name.startsWith('Ficticio ');
                return DataColumn(
                  label: Text(
                    name,
                    style: TextStyle(
                      color: isFictitious
                          ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                          : colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              const DataColumn(label: Text('Disponible')),
            ],
            rows: [
              ...List.generate(problem.rowCount, (row) {
                final origName = problem.originNames[row];
                final origId = row < problem.originIds.length
                    ? problem.originIds[row]
                    : '';
                final isOriginFictitious =
                    origId == 'nw_dummy_origin' ||
                    origName == 'Ficticio' ||
                    origName.startsWith('Ficticio ');
                return DataRow(
                  color: isOriginFictitious
                      ? WidgetStatePropertyAll(
                          colors.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                        )
                      : null,
                  cells: [
                    DataCell(
                      Text(
                        origName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isOriginFictitious
                              ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                              : colors.onSurface,
                        ),
                      ),
                    ),
                    ...List.generate(problem.destinationNames.length, (col) {
                      final destName = problem.destinationNames[col];
                      final destId = col < problem.destinationIds.length
                          ? problem.destinationIds[col]
                          : '';
                      final isDestFictitious =
                          destId == 'nw_dummy_destination' ||
                          destName == 'Ficticio' ||
                          destName.startsWith('Ficticio ');
                      final isCellFictitious =
                          isOriginFictitious || isDestFictitious;
                      final value = allocations[row][col];
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: isCellFictitious
                              ? BoxDecoration(
                                  color: colors.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          child: Text(
                            _formatNumber(value),
                            style: TextStyle(
                              color: isCellFictitious
                                  ? colors.onSurfaceVariant.withValues(
                                      alpha: 0.45,
                                    )
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        _formatNumber(problem.supplies[row]),
                        style: TextStyle(
                          color: isOriginFictitious
                              ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                              : colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              DataRow(
                color: WidgetStatePropertyAll(
                  colors.tertiaryContainer.withValues(alpha: .55),
                ),
                cells: [
                  const DataCell(
                    Text(
                      'Demanda',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ...List.generate(problem.destinationNames.length, (col) {
                    final destName = problem.destinationNames[col];
                    final destId = col < problem.destinationIds.length
                        ? problem.destinationIds[col]
                        : '';
                    final isDestFictitious =
                        destId == 'nw_dummy_destination' ||
                        destName == 'Ficticio' ||
                        destName.startsWith('Ficticio ');
                    final value = problem.demands[col];
                    return DataCell(
                      Text(
                        _formatNumber(value),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDestFictitious
                              ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                              : colors.onTertiaryContainer,
                        ),
                      ),
                    );
                  }),
                  const DataCell(Text('')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cellName(TransportationInput problem, TransportCell? cell) {
  if (cell == null) return '';
  return '${problem.originNames[cell.row]} → ${problem.destinationNames[cell.column]}';
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
