import 'package:flutter/material.dart';

import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../domain/services/assignment_bipartite_service.dart';

class BipartiteMatrixGridTable extends StatefulWidget {
  final Grafo grafo;
  final List<Nodo> origins;
  final List<Nodo> destinations;
  final bool isNorthwest;
  final int? selectedRowIndex;
  final int? selectedColumnIndex;
  final Function(int?, int?) onSelectionChanged;

  const BipartiteMatrixGridTable({
    super.key,
    required this.grafo,
    required this.origins,
    required this.destinations,
    required this.isNorthwest,
    required this.selectedRowIndex,
    required this.selectedColumnIndex,
    required this.onSelectionChanged,
  });

  @override
  State<BipartiteMatrixGridTable> createState() =>
      _BipartiteMatrixGridTableState();
}

class _BipartiteMatrixGridTableState extends State<BipartiteMatrixGridTable> {
  static const double cellWidth = 84.0;
  static const double cellHeight = 52.0;
  static const double rowHeaderWidth = 90.0;
  static const double bracketWidth = 14.0;
  static const double bracketGap = 10.0;

  static const double totalLeftOffset =
      rowHeaderWidth + bracketGap + bracketWidth + bracketGap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Calculate row sums and degrees (Origins)
    final rowSums = <double>[];
    final rowDegrees = <int>[];
    for (final orig in widget.origins) {
      double sum = 0.0;
      int deg = 0;
      for (final dest in widget.destinations) {
        final w = AssignmentBipartiteService.getConnectionWeight(
          widget.grafo,
          orig.id,
          dest.id,
        );
        if (w != null) {
          sum += w;
          deg += 1;
        }
      }
      rowSums.add(sum);
      rowDegrees.add(deg);
    }

    // 2. Calculate column sums and degrees (Destinations)
    final colSums = <double>[];
    final colDegrees = <int>[];
    for (final dest in widget.destinations) {
      double sum = 0.0;
      int deg = 0;
      for (final orig in widget.origins) {
        final w = AssignmentBipartiteService.getConnectionWeight(
          widget.grafo,
          orig.id,
          dest.id,
        );
        if (w != null) {
          sum += w;
          deg += 1;
        }
      }
      colSums.add(sum);
      colDegrees.add(deg);
    }

    final matrixHeight = widget.origins.length * (cellHeight + 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Row: Destination column headers + Summary Column Headers
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: totalLeftOffset),
            // Destination column headers
            ...List.generate(widget.destinations.length, (j) {
              final isColSelected = widget.selectedColumnIndex == j;
              final destNode = widget.destinations[j];
              final label = destNode.nombre ?? destNode.id;

              return GestureDetector(
                onTap: () {
                  widget.onSelectionChanged(
                    widget.selectedRowIndex,
                    isColSelected ? null : j,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: cellWidth,
                  height: cellHeight,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isColSelected
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isColSelected
                          ? colorScheme.secondary
                          : colorScheme.outlineVariant,
                      width: isColSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isColSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.secondary,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: bracketGap + bracketWidth + bracketGap),

            // Summary Header 1: Suma Fila
            _buildHeaderCell(
              context: context,
              label: 'Suma Fila',
              isSelected:
                  widget.selectedColumnIndex == widget.destinations.length,
              onTap: () {
                widget.onSelectionChanged(
                  widget.selectedRowIndex,
                  widget.selectedColumnIndex == widget.destinations.length
                      ? null
                      : widget.destinations.length,
                );
              },
              colorScheme: colorScheme,
              isSum: true,
              width: cellWidth,
              height: cellHeight,
            ),

            // Summary Header 2: Grado Fila
            _buildHeaderCell(
              context: context,
              label: 'Grado Fila',
              isSelected:
                  widget.selectedColumnIndex == widget.destinations.length + 1,
              onTap: () {
                widget.onSelectionChanged(
                  widget.selectedRowIndex,
                  widget.selectedColumnIndex == widget.destinations.length + 1
                      ? null
                      : widget.destinations.length + 1,
                );
              },
              colorScheme: colorScheme,
              isSum: false,
              width: cellWidth,
              height: cellHeight,
            ),

            // Summary Header 3: Oferta (Supply) - only for Northwest / Transportation
            if (widget.isNorthwest)
              _buildHeaderCell(
                context: context,
                label: 'Oferta',
                isSelected:
                    widget.selectedColumnIndex ==
                    widget.destinations.length + 2,
                onTap: () {
                  widget.onSelectionChanged(
                    widget.selectedRowIndex,
                    widget.selectedColumnIndex == widget.destinations.length + 2
                        ? null
                        : widget.destinations.length + 2,
                  );
                },
                colorScheme: colorScheme,
                isSum: true,
                customColor: colorScheme.error,
                width: cellWidth,
                height: cellHeight,
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Middle Section: Origin Row Headers + Left Bracket '[' + Cells Grid + Right Bracket ']' + Row Summaries
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Origin Row Headers
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.origins.length, (i) {
                final isRowSelected = widget.selectedRowIndex == i;
                final origNode = widget.origins[i];
                final label = origNode.nombre ?? origNode.id;

                return GestureDetector(
                  onTap: () {
                    widget.onSelectionChanged(
                      isRowSelected ? null : i,
                      widget.selectedColumnIndex,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: rowHeaderWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isRowSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRowSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: isRowSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isRowSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: bracketGap),

            // Left bracket '['
            Container(
              height: matrixHeight,
              width: bracketWidth,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.onSurface, width: 3),
                  left: BorderSide(color: colorScheme.onSurface, width: 3),
                  bottom: BorderSide(color: colorScheme.onSurface, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: bracketGap),

            // Bipartite Grid Cells
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.origins.length, (i) {
                final origNode = widget.origins[i];
                final isRowSelected = widget.selectedRowIndex == i;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.destinations.length, (j) {
                      final destNode = widget.destinations[j];
                      final weight =
                          AssignmentBipartiteService.getConnectionWeight(
                            widget.grafo,
                            origNode.id,
                            destNode.id,
                          );

                      final isColSelected = widget.selectedColumnIndex == j;
                      final isCellSelected =
                          widget.selectedRowIndex == i &&
                          widget.selectedColumnIndex == j;
                      final isHighlighted = isRowSelected || isColSelected;

                      final hasConnection = weight != null;
                      final cellText =
                          AssignmentBipartiteService.formatCellText(weight);

                      Color bgColor = Colors.transparent;
                      if (isCellSelected) {
                        bgColor = colorScheme.primaryContainer;
                      } else if (isColSelected) {
                        bgColor = colorScheme.secondaryContainer.withValues(
                          alpha: 0.35,
                        );
                      } else if (isRowSelected) {
                        bgColor = colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        );
                      }

                      Color textColor = hasConnection
                          ? (isCellSelected
                                ? colorScheme.onPrimaryContainer
                                : (isHighlighted
                                      ? colorScheme.primary
                                      : colorScheme.onSurface))
                          : colorScheme.outline.withValues(alpha: 0.4);

                      final tooltipText =
                          '${origNode.nombre ?? origNode.id} → ${destNode.nombre ?? destNode.id}\n'
                          '${hasConnection ? "Costo: $cellText" : "Sin conexión directa"}';

                      return GestureDetector(
                        onTap: () {
                          if (widget.selectedRowIndex == i &&
                              widget.selectedColumnIndex == j) {
                            widget.onSelectionChanged(null, null);
                          } else {
                            widget.onSelectionChanged(i, j);
                          }
                        },
                        child: Tooltip(
                          message: tooltipText,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: TextStyle(
                            color: colorScheme.surface,
                            fontSize: 12,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: cellWidth,
                            height: cellHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: isCellSelected
                                  ? Border.all(
                                      color: colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                cellText,
                                style: TextStyle(
                                  fontWeight: hasConnection
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),

            const SizedBox(width: bracketGap),

            // Right bracket ']'
            Container(
              height: matrixHeight,
              width: bracketWidth,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.onSurface, width: 3),
                  right: BorderSide(color: colorScheme.onSurface, width: 3),
                  bottom: BorderSide(color: colorScheme.onSurface, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),

            const SizedBox(width: bracketGap),

            // 2 Summary Columns OUTSIDE ] (Suma Fila & Grado Fila)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.origins.length, (i) {
                final isRowSelected = widget.selectedRowIndex == i;
                final origNode = widget.origins[i];
                final origLabel = origNode.nombre ?? origNode.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Suma Fila
                      _buildSummaryCell(
                        context: context,
                        text: AssignmentBipartiteService.formatCellText(
                          rowSums[i],
                        ),
                        tooltip:
                            'Suma total de costos para el origen $origLabel',
                        isSum: true,
                        isSelected:
                            isRowSelected ||
                            widget.selectedColumnIndex ==
                                widget.destinations.length,
                        colorScheme: colorScheme,
                        width: cellWidth,
                        height: cellHeight,
                      ),
                      // Grado Fila
                      _buildSummaryCell(
                        context: context,
                        text: '${rowDegrees[i]}',
                        tooltip: 'Conexiones emitidas por el origen $origLabel',
                        isSum: false,
                        isSelected:
                            isRowSelected ||
                            widget.selectedColumnIndex ==
                                widget.destinations.length + 1,
                        colorScheme: colorScheme,
                        width: cellWidth,
                        height: cellHeight,
                      ),
                      // Oferta (Supply) - only for Northwest / Transportation
                      if (widget.isNorthwest)
                        _buildSummaryCell(
                          context: context,
                          text: AssignmentBipartiteService.formatCellText(
                            origNode.cantidad ?? 0,
                          ),
                          tooltip: 'Oferta disponible en el origen $origLabel',
                          isSum: true,
                          customColor: colorScheme.error,
                          isSelected:
                              isRowSelected ||
                              widget.selectedColumnIndex ==
                                  widget.destinations.length + 2,
                          colorScheme: colorScheme,
                          width: cellWidth,
                          height: cellHeight,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Bottom Summary Section: 2 Summary Rows BELOW Brackets [ ]
        // Row 1: Suma Columna
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderCell(
              context: context,
              label: 'Suma Col.',
              isSelected: widget.selectedRowIndex == widget.origins.length,
              onTap: () {
                widget.onSelectionChanged(
                  widget.selectedRowIndex == widget.origins.length
                      ? null
                      : widget.origins.length,
                  widget.selectedColumnIndex,
                );
              },
              colorScheme: colorScheme,
              isSum: true,
              width: rowHeaderWidth,
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            ...List.generate(widget.destinations.length, (j) {
              final isColSelected = widget.selectedColumnIndex == j;
              final destNode = widget.destinations[j];
              final destLabel = destNode.nombre ?? destNode.id;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSummaryCell(
                  context: context,
                  text: AssignmentBipartiteService.formatCellText(colSums[j]),
                  tooltip: 'Suma total de costos para el destino $destLabel',
                  isSum: true,
                  isSelected:
                      isColSelected ||
                      widget.selectedRowIndex == widget.origins.length,
                  colorScheme: colorScheme,
                  width: cellWidth,
                  height: cellHeight,
                ),
              );
            }),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
          ],
        ),

        // Row 2: Grado Columna
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderCell(
              context: context,
              label: 'Grado Col.',
              isSelected: widget.selectedRowIndex == widget.origins.length + 1,
              onTap: () {
                widget.onSelectionChanged(
                  widget.selectedRowIndex == widget.origins.length + 1
                      ? null
                      : widget.origins.length + 1,
                  widget.selectedColumnIndex,
                );
              },
              colorScheme: colorScheme,
              isSum: false,
              width: rowHeaderWidth,
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            ...List.generate(widget.destinations.length, (j) {
              final isColSelected = widget.selectedColumnIndex == j;
              final destNode = widget.destinations[j];
              final destLabel = destNode.nombre ?? destNode.id;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSummaryCell(
                  context: context,
                  text: '${colDegrees[j]}',
                  tooltip: 'Conexiones recibidas por el destino $destLabel',
                  isSum: false,
                  isSelected:
                      isColSelected ||
                      widget.selectedRowIndex == widget.origins.length + 1,
                  colorScheme: colorScheme,
                  width: cellWidth,
                  height: cellHeight,
                ),
              );
            }),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
          ],
        ),

        // Row 3: Demanda (Demand) - only for Northwest / Transportation
        if (widget.isNorthwest)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderCell(
                context: context,
                label: 'Demanda',
                isSelected:
                    widget.selectedRowIndex == widget.origins.length + 2,
                onTap: () {
                  widget.onSelectionChanged(
                    widget.selectedRowIndex == widget.origins.length + 2
                        ? null
                        : widget.origins.length + 2,
                    widget.selectedColumnIndex,
                  );
                },
                colorScheme: colorScheme,
                isSum: true,
                customColor: colorScheme.error,
                width: rowHeaderWidth,
                height: cellHeight,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
              const SizedBox(width: bracketGap + bracketWidth + bracketGap),
              ...List.generate(widget.destinations.length, (j) {
                final isColSelected = widget.selectedColumnIndex == j;
                final destNode = widget.destinations[j];
                final destLabel = destNode.nombre ?? destNode.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildSummaryCell(
                    context: context,
                    text: AssignmentBipartiteService.formatCellText(
                      destNode.cantidad ?? 0,
                    ),
                    tooltip: 'Demanda requerida por el destino $destLabel',
                    isSum: true,
                    customColor: colorScheme.error,
                    isSelected:
                        isColSelected ||
                        widget.selectedRowIndex == widget.origins.length + 2,
                    colorScheme: colorScheme,
                    width: cellWidth,
                    height: cellHeight,
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  static Widget _buildHeaderCell({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isSum,
    required double width,
    required double height,
    EdgeInsetsGeometry? margin,
    Color? customColor,
  }) {
    final baseColor =
        customColor ?? (isSum ? colorScheme.primary : colorScheme.secondary);
    final baseContainer = customColor != null
        ? colorScheme.errorContainer
        : (isSum
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer);

    final bgColor = isSelected
        ? baseContainer
        : baseContainer.withValues(alpha: 0.3);
    final borderColor = isSelected
        ? baseColor
        : baseColor.withValues(alpha: 0.4);
    final textColor = isSelected
        ? (customColor != null
              ? colorScheme.onErrorContainer
              : (isSum
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer))
        : baseColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        alignment: Alignment.center,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: textColor,
          ),
        ),
      ),
    );
  }

  static Widget _buildSummaryCell({
    required BuildContext context,
    required String text,
    required String tooltip,
    required bool isSum,
    required bool isSelected,
    required ColorScheme colorScheme,
    required double width,
    required double height,
    Color? customColor,
  }) {
    final baseColor =
        customColor ?? (isSum ? colorScheme.primary : colorScheme.secondary);
    final baseContainer = customColor != null
        ? colorScheme.errorContainer
        : (isSum
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer);

    final bg = isSelected
        ? baseContainer
        : baseContainer.withValues(alpha: 0.2);
    final textColor = isSelected
        ? (customColor != null
              ? colorScheme.onErrorContainer
              : (isSum
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer))
        : baseColor;

    return Tooltip(
      message: tooltip,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.onSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: colorScheme.surface, fontSize: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? baseColor : baseColor.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
