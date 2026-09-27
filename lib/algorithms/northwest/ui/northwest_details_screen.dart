import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/math_rich_text.dart';
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.8),
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
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                                width: 0.8,
                              ),
                            ),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHigh,
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
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(
                                    problem.destinationNames.length,
                                    (col) {
                                      final name =
                                          problem.destinationNames[col];
                                      final id =
                                          col < problem.destinationIds.length
                                          ? problem.destinationIds[col]
                                          : '';
                                      final isFictitious =
                                          id == 'nw_dummy_destination' ||
                                          name == 'Ficticio' ||
                                          name.startsWith('Ficticio ');
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isFictitious
                                                  ? colors.onSurfaceVariant
                                                        .withValues(alpha: 0.5)
                                                  : colors.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Disponible',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: colors.secondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ...List.generate(problem.rowCount, (row) {
                                final origName = problem.originNames[row];
                                final origId = row < problem.originIds.length
                                    ? problem.originIds[row]
                                    : '';
                                final isOriginFictitious =
                                    origId == 'nw_dummy_origin' ||
                                    origName == 'Ficticio' ||
                                    origName.startsWith('Ficticio ');
                                return TableRow(
                                  decoration: isOriginFictitious
                                      ? BoxDecoration(
                                          color: colors.surfaceContainerHighest
                                              .withValues(alpha: 0.35),
                                        )
                                      : null,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        origName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                                        final isAllocated = value > 0;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          alignment: Alignment.center,
                                          color:
                                              isAllocated && !isCellFictitious
                                              ? colors.primaryContainer
                                                    .withValues(alpha: 0.45)
                                              : (isCellFictitious
                                                    ? colors
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                            alpha: 0.25,
                                                          )
                                                    : null),
                                          child: Text(
                                            _formatNumber(value),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isAllocated
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isCellFictitious
                                                  ? colors.onSurfaceVariant
                                                        .withValues(alpha: 0.45)
                                                  : (isAllocated
                                                        ? colors.primary
                                                        : colors.onSurface),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _formatNumber(problem.supplies[row]),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isOriginFictitious
                                              ? colors.onSurfaceVariant
                                                    .withValues(alpha: 0.5)
                                              : colors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              TableRow(
                                decoration: BoxDecoration(
                                  color: colors.tertiaryContainer.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Demanda',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: colors.onTertiaryContainer,
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
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _formatNumber(problem.demands[col]),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isDestFictitious
                                                ? colors.onSurfaceVariant
                                                      .withValues(alpha: 0.5)
                                                : colors.onTertiaryContainer,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
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

class _NorthwestStepByStep extends StatefulWidget {
  final TransportationInput problem;
  final NorthwestResult result;

  const _NorthwestStepByStep({required this.problem, required this.result});

  @override
  State<_NorthwestStepByStep> createState() => _NorthwestStepByStepState();
}

class _NorthwestStepByStepState extends State<_NorthwestStepByStep> {
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
    final totalSteps = 1 + widget.result.iterations.length;

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
          'Cada tarjeta reúne las operaciones completas de una iteración. Navega horizontalmente entre los pasos:',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 14),

        // Horizontal Step Selector Bar
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalSteps,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == _currentStep;
              String label;
              if (index == 0) {
                label = '1. Solución Inicial';
              } else {
                final iter = widget.result.iterations[index - 1];
                label = iter.isOptimal
                    ? '${index + 1}. Solución Óptima'
                    : '${index + 1}. Iteración MODI ${iter.number}';
              }

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
                label: Text(label),
                onSelected: (_) => _goToStep(index),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Iteration Cards Carousel View
        SizedBox(
          height: 620,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalSteps,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildInitialStepCard(colors);
              }
              final iteration = widget.result.iterations[index - 1];
              return _buildModiIterationCard(colors, iteration, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitialStepCard(ColorScheme colors) {
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    child: const Text(
                      '1',
                      style: TextStyle(
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
                        const Text(
                          'Solución Inicial (Regla de la Esquina Noroeste)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Z inicial = ${_formatNumber(widget.result.initialObjectiveValue)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Se comienza en la casilla (1,1) superior izquierda y en cada paso se asigna el máximo posible min(oferta, demanda) restante, desplazándose a la derecha al agotar oferta o hacia abajo al agotar demanda.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              _AllocationTable(
                problem: widget.problem,
                allocations: widget.result.initialAllocations,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModiIterationCard(
    ColorScheme colors,
    ModiIteration iteration,
    int stepNumber,
  ) {
    final entering = iteration.enteringCell;
    final isOptimal = iteration.isOptimal;

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
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isOptimal
                        ? Colors.green.shade700
                        : colors.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      '$stepNumber',
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
                          isOptimal
                              ? 'Comprobación de Optimalidad MODI'
                              : 'Iteración MODI ${iteration.number}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isOptimal
                              ? 'Solución óptima alcanzada'
                              : 'Entra: ${_cellName(widget.problem, entering)} · α = ${_formatNumber(iteration.alpha!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOptimal
                                ? Colors.green.shade700
                                : colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Step operations
              _PotentialTable(problem: widget.problem, iteration: iteration),
              const SizedBox(height: 14),
              _LabeledMatrix(
                title: r'Matriz de Costos Relativos ($G_{ij} = u_i + v_j$)',
                problem: widget.problem,
                values: iteration.opportunityMatrix,
              ),
              const SizedBox(height: 14),
              _LabeledMatrix(
                title: r'Matriz $\Delta_{ij} = c_{ij} - G_{ij}$',
                problem: widget.problem,
                values: iteration.deltas,
                highlightedCell: entering,
              ),
              if (!isOptimal) ...[
                const SizedBox(height: 14),
                Text(
                  widget.problem.objective == TransportationObjective.minimize
                      ? 'Se selecciona la celda no básica con delta negativo de mayor magnitud: ${_cellName(widget.problem, entering)}.'
                      : 'Se selecciona la celda no básica con delta positivo de mayor magnitud: ${_cellName(widget.problem, entering)}.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                _CircuitView(problem: widget.problem, iteration: iteration),
                const SizedBox(height: 14),
                Text(
                  'Nueva Distribución Resultante · Z = ${_formatNumber(iteration.objectiveValue)}',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _AllocationTable(
                  problem: widget.problem,
                  allocations: iteration.allocations,
                ),
              ] else ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.problem.objective == TransportationObjective.minimize ? "Todas las diferencias no básicas Δ son ≥ 0" : "Todas las diferencias no básicas Δ son ≤ 0"}. La solución actual es ÓPTIMA con Z = ${_formatNumber(iteration.objectiveValue)}.',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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

class _PotentialTable extends StatelessWidget {
  final TransportationInput problem;
  final ModiIteration iteration;

  const _PotentialTable({required this.problem, required this.iteration});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Potenciales MODI',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildTable(
              context,
              names: problem.originNames,
              values: iteration.rowPotentials,
              prefix: 'u',
              headerColor: colors.secondaryContainer,
              textColor: colors.onSecondaryContainer,
            ),
            _buildTable(
              context,
              names: problem.destinationNames,
              values: iteration.columnPotentials,
              prefix: 'v',
              headerColor: colors.tertiaryContainer,
              textColor: colors.onTertiaryContainer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context, {
    required List<String> names,
    required List<double> values,
    required String prefix,
    required Color headerColor,
    required Color textColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.8),
          width: 1.2,
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
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: List.generate(values.length, (i) {
                final name = i < names.length ? names[i] : '${prefix}_${i + 1}';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: MathRichText(
                      text: '$name (\$${prefix}_{${i + 1}}\$)',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
            TableRow(
              children: values.map((val) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: Text(
                      _formatNumber(val),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
        MathRichText(
          text: title,
          baseStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(72),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
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
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.8),
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
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.surfaceContainerHigh),
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
                          color: colors.primary,
                        ),
                      ),
                    ),
                    ...List.generate(problem.destinationNames.length, (col) {
                      final name = problem.destinationNames[col];
                      final id = col < problem.destinationIds.length
                          ? problem.destinationIds[col]
                          : '';
                      final isFictitious =
                          id == 'nw_dummy_destination' ||
                          name == 'Ficticio' ||
                          name.startsWith('Ficticio ');
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isFictitious
                                  ? colors.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    )
                                  : colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Text(
                          'Disponible',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ...List.generate(problem.rowCount, (row) {
                  final origName = problem.originNames[row];
                  final origId = row < problem.originIds.length
                      ? problem.originIds[row]
                      : '';
                  final isOriginFictitious =
                      origId == 'nw_dummy_origin' ||
                      origName == 'Ficticio' ||
                      origName.startsWith('Ficticio ');
                  return TableRow(
                    decoration: isOriginFictitious
                        ? BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            ),
                          )
                        : null,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          origName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                        final isAllocated = value > 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          alignment: Alignment.center,
                          color: isAllocated && !isCellFictitious
                              ? colors.primaryContainer.withValues(alpha: 0.45)
                              : (isCellFictitious
                                    ? colors.surfaceContainerHighest.withValues(
                                        alpha: 0.25,
                                      )
                                    : null),
                          child: Text(
                            _formatNumber(value),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isAllocated
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCellFictitious
                                  ? colors.onSurfaceVariant.withValues(
                                      alpha: 0.45,
                                    )
                                  : (isAllocated
                                        ? colors.primary
                                        : colors.onSurface),
                            ),
                          ),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _formatNumber(problem.supplies[row]),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isOriginFictitious
                                ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer.withValues(alpha: 0.4),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Demanda',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: colors.onTertiaryContainer,
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
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _formatNumber(problem.demands[col]),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDestFictitious
                                ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                                : colors.onTertiaryContainer,
                          ),
                        ),
                      );
                    }),
                    const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
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
