import 'package:flutter/material.dart';

import '../../../../ui/widgets/math_rich_text.dart';
import '../../domain/models/northwest_models.dart';

class NorthwestLabeledMatrix extends StatelessWidget {
  final String title;
  final TransportationInput problem;
  final List<List<double>> values;
  final TransportCell? highlightedCell;

  const NorthwestLabeledMatrix({
    super.key,
    required this.title,
    required this.problem,
    required this.values,
    this.highlightedCell,
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
        MathRichText(
          text: title,
          baseStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: IntrinsicWidth(
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
                        const _NorthwestMatrixCell(text: ''),
                        ...problem.destinationNames.map(
                          (name) =>
                              _NorthwestMatrixCell(text: name, isHeader: true),
                        ),
                      ],
                    ),
                    ...List.generate(
                      values.length,
                      (row) => TableRow(
                        children: [
                          _NorthwestMatrixCell(
                            text: problem.originNames[row],
                            isHeader: true,
                          ),
                          ...List.generate(
                            values[row].length,
                            (column) => _NorthwestMatrixCell(
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
        ),
      ],
    );
  }
}

class _NorthwestMatrixCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool highlighted;

  const _NorthwestMatrixCell({
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
