import 'package:flutter/material.dart';

import '../../domain/models/northwest_models.dart';

class NorthwestCircuitView extends StatelessWidget {
  final TransportationInput problem;
  final ModiIteration iteration;

  const NorthwestCircuitView({
    super.key,
    required this.problem,
    required this.iteration,
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
