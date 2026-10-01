import 'package:flutter/material.dart';

import '../../domain/models/northwest_models.dart';

class NorthwestDistributionTable extends StatelessWidget {
  final TransportationInput problem;
  final List<List<double>> allocations;

  const NorthwestDistributionTable({
    super.key,
    required this.problem,
    required this.allocations,
  });

  NorthwestDistributionTable.fromResult({
    super.key,
    required this.problem,
    required NorthwestResult result,
  }) : allocations = result.allocations;

  static String formatNumber(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  bool _isFictitiousOrigin(int row) {
    final name = problem.originNames[row];
    final id = row < problem.originIds.length ? problem.originIds[row] : '';
    return id == 'nw_dummy_origin' ||
        name == 'Ficticio' ||
        name.startsWith('Ficticio ');
  }

  bool _isFictitiousDestination(int col) {
    final name = problem.destinationNames[col];
    final id = col < problem.destinationIds.length
        ? problem.destinationIds[col]
        : '';
    return id == 'nw_dummy_destination' ||
        name == 'Ficticio' ||
        name.startsWith('Ficticio ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
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
                  _buildHeaderRow(colors),
                  ...List.generate(
                    problem.rowCount,
                    (row) => _buildDataRow(colors, row),
                  ),
                  _buildFooterRow(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(ColorScheme colors) {
    return TableRow(
      decoration: BoxDecoration(color: colors.surfaceContainerHigh),
      children: [
        _HeaderCell(text: 'Origen', textColor: colors.primary, alignLeft: true),
        ...List.generate(problem.destinationNames.length, (col) {
          final isFictitious = _isFictitiousDestination(col);
          return _HeaderCell(
            text: problem.destinationNames[col],
            textColor: isFictitious
                ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                : colors.primary,
          );
        }),
        _HeaderCell(text: 'Oferta', textColor: colors.secondary),
      ],
    );
  }

  TableRow _buildDataRow(ColorScheme colors, int row) {
    final origName = problem.originNames[row];
    final isOriginFictitious = _isFictitiousOrigin(row);

    return TableRow(
      decoration: isOriginFictitious
          ? BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
            )
          : null,
      children: [
        _DataCellLabel(text: origName, isFictitious: isOriginFictitious),
        ...List.generate(problem.destinationNames.length, (col) {
          final isDestFictitious = _isFictitiousDestination(col);
          final isCellFictitious = isOriginFictitious || isDestFictitious;
          final value = allocations[row][col];
          return _DataCell(value: value, isFictitious: isCellFictitious);
        }),
        _DataCellTotal(
          value: problem.supplies[row],
          isFictitious: isOriginFictitious,
          textColor: colors.secondary,
        ),
      ],
    );
  }

  TableRow _buildFooterRow(ColorScheme colors) {
    return TableRow(
      children: [
        _FooterCellLabel(text: 'Demanda', textColor: colors.secondary),
        ...List.generate(problem.destinationNames.length, (col) {
          final isFictitious = _isFictitiousDestination(col);
          return _FooterCell(
            value: problem.demands[col],
            isFictitious: isFictitious,
            textColor: colors.secondary,
          );
        }),
        const SizedBox.shrink(),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final Color textColor;
  final bool alignLeft;

  const _HeaderCell({
    required this.text,
    required this.textColor,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: textColor,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: alignLeft ? content : Center(child: content),
    );
  }
}

class _DataCellLabel extends StatelessWidget {
  final String text;
  final bool isFictitious;

  const _DataCellLabel({required this.text, required this.isFictitious});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isFictitious
              ? colors.onSurfaceVariant.withValues(alpha: 0.5)
              : colors.onSurface,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final double value;
  final bool isFictitious;

  const _DataCell({required this.value, required this.isFictitious});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAllocated = value > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      color: isAllocated && !isFictitious
          ? colors.primaryContainer.withValues(alpha: 0.45)
          : (isFictitious
                ? colors.surfaceContainerHighest.withValues(alpha: 0.25)
                : null),
      child: Text(
        NorthwestDistributionTable.formatNumber(value),
        style: TextStyle(
          fontSize: 12,
          fontWeight: isAllocated ? FontWeight.bold : FontWeight.normal,
          color: isFictitious
              ? colors.onSurfaceVariant.withValues(alpha: 0.45)
              : (isAllocated ? colors.primary : colors.onSurface),
        ),
      ),
    );
  }
}

class _DataCellTotal extends StatelessWidget {
  final double value;
  final bool isFictitious;
  final Color textColor;

  const _DataCellTotal({
    required this.value,
    required this.isFictitious,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        NorthwestDistributionTable.formatNumber(value),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isFictitious
              ? colors.onSurfaceVariant.withValues(alpha: 0.5)
              : textColor,
        ),
      ),
    );
  }
}

class _FooterCellLabel extends StatelessWidget {
  final String text;
  final Color textColor;

  const _FooterCellLabel({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}

class _FooterCell extends StatelessWidget {
  final double value;
  final bool isFictitious;
  final Color textColor;

  const _FooterCell({
    required this.value,
    required this.isFictitious,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        NorthwestDistributionTable.formatNumber(value),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isFictitious
              ? colors.onSurfaceVariant.withValues(alpha: 0.5)
              : textColor,
        ),
      ),
    );
  }
}
