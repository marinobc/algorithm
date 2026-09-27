import 'package:flutter/material.dart';

import '../../domain/models/northwest_models.dart';
import 'northwest_circuit_view.dart';
import 'northwest_distribution_table.dart';
import 'northwest_labeled_matrix.dart';
import 'northwest_potential_table.dart';

class NorthwestModiIterationCard extends StatelessWidget {
  final TransportationInput problem;
  final ModiIteration iteration;
  final int stepNumber;

  const NorthwestModiIterationCard({
    super.key,
    required this.problem,
    required this.iteration,
    required this.stepNumber,
  });

  static String _cellName(TransportationInput problem, TransportCell? cell) {
    if (cell == null) return '';
    return '${problem.originNames[cell.row]} → ${problem.destinationNames[cell.column]}';
  }

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                    backgroundColor:
                        isOptimal ? Colors.green.shade700 : colors.primary,
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
                              : 'Entra: ${_cellName(problem, entering)} · α = ${_formatNumber(iteration.alpha!)}',
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
              NorthwestPotentialTable(
                problem: problem,
                iteration: iteration,
              ),
              const SizedBox(height: 14),
              NorthwestLabeledMatrix(
                title: r'Matriz de Costos Relativos ($G_{ij} = u_i + v_j$)',
                problem: problem,
                values: iteration.opportunityMatrix,
              ),
              const SizedBox(height: 14),
              NorthwestLabeledMatrix(
                title: r'Matriz $\Delta_{ij} = c_{ij} - G_{ij}$',
                problem: problem,
                values: iteration.deltas,
                highlightedCell: entering,
              ),
              if (!isOptimal) ...[
                const SizedBox(height: 14),
                Text(
                  problem.objective == TransportationObjective.minimize
                      ? 'Se selecciona la celda no básica con delta negativo de mayor magnitud: ${_cellName(problem, entering)}.'
                      : 'Se selecciona la celda no básica con delta positivo de mayor magnitud: ${_cellName(problem, entering)}.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                NorthwestCircuitView(
                  problem: problem,
                  iteration: iteration,
                ),
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
                NorthwestDistributionTable(
                  problem: problem,
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
                    '${problem.objective == TransportationObjective.minimize ? "Todas las diferencias no básicas Δ son ≥ 0" : "Todas las diferencias no básicas Δ son ≤ 0"}. La solución actual es ÓPTIMA con Z = ${_formatNumber(iteration.objectiveValue)}.',
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
