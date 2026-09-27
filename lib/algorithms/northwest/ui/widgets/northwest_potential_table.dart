import 'package:flutter/material.dart';

import '../../../../ui/widgets/math_rich_text.dart';
import '../../domain/models/northwest_models.dart';

class NorthwestPotentialTable extends StatelessWidget {
  final TransportationInput problem;
  final ModiIteration iteration;

  const NorthwestPotentialTable({
    super.key,
    required this.problem,
    required this.iteration,
  });

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
          'Potenciales MODI',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
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
