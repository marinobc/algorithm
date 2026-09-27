import 'package:flutter/material.dart';

import '../../domain/models/northwest_models.dart';
import 'northwest_distribution_table.dart';
import 'northwest_modi_iteration_card.dart';

class NorthwestStepByStepWidget extends StatefulWidget {
  final TransportationInput problem;
  final NorthwestResult result;

  const NorthwestStepByStepWidget({
    super.key,
    required this.problem,
    required this.result,
  });

  @override
  State<NorthwestStepByStepWidget> createState() =>
      _NorthwestStepByStepWidgetState();
}

class _NorthwestStepByStepWidgetState
    extends State<NorthwestStepByStepWidget> {
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

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalSteps = 1 + widget.result.iterations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolución paso a paso',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
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
                  color:
                      isSelected ? colors.onPrimary : colors.onSurfaceVariant,
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
              return NorthwestModiIterationCard(
                problem: widget.problem,
                iteration: iteration,
                stepNumber: index + 1,
              );
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
              NorthwestDistributionTable(
                problem: widget.problem,
                allocations: widget.result.initialAllocations,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
