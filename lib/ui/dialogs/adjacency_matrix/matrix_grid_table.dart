import 'package:flutter/material.dart';

import '../../../domain/services/adjacency_matrix_service.dart';

class MatrixGridTable extends StatelessWidget {
  final AdjacencyMatrixData matrixData;
  final int? selectedRowIndex;
  final int? selectedColumnIndex;
  final void Function(int? row, int? col) onCellTapped;
  final void Function(int col) onColumnHeaderTapped;
  final void Function(int row) onRowHeaderTapped;
  final void Function(int row) onRowSummaryHeaderTapped;
  final void Function(int col) onColSummaryHeaderTapped;
  final ColorScheme colorScheme;

  const MatrixGridTable({
    super.key,
    required this.matrixData,
    required this.selectedRowIndex,
    required this.selectedColumnIndex,
    required this.onCellTapped,
    required this.onColumnHeaderTapped,
    required this.onRowHeaderTapped,
    required this.onRowSummaryHeaderTapped,
    required this.onColSummaryHeaderTapped,
    required this.colorScheme,
  });

  static const double cellWidth = 76.0;
  static const double cellHeight = 52.0;
  static const double rowHeaderWidth = 76.0;
  static const double bracketWidth = 14.0;
  static const double bracketGap = 12.0;

  static const double totalLeftOffset =
      rowHeaderWidth + bracketGap + bracketWidth + bracketGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Row: Column Headers
        Row(
          children: [
            const SizedBox(width: totalLeftOffset),
            // Standard Node Headers
            ...List.generate(matrixData.labels.length, (j) {
              final colName = matrixData.labels[j];
              final isColSelected = selectedColumnIndex == j;

              return GestureDetector(
                onTap: () => onColumnHeaderTapped(j),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: cellWidth,
                  height: cellHeight,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isColSelected
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isColSelected
                          ? colorScheme.secondary
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    colName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isColSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            // Extra Summary Header 1: Suma Fila
            _buildHeaderCell(
              context: context,
              label: 'Suma Fila',
              isSelected: selectedColumnIndex == matrixData.labels.length,
              onTap: () => onColSummaryHeaderTapped(matrixData.labels.length),
              colorScheme: colorScheme,
              isSum: true,
              width: cellWidth,
              height: cellHeight,
            ),
            // Extra Summary Header 2: Grado Fila
            _buildHeaderCell(
              context: context,
              label: 'Grado Fila',
              isSelected: selectedColumnIndex == matrixData.labels.length + 1,
              onTap: () =>
                  onColSummaryHeaderTapped(matrixData.labels.length + 1),
              colorScheme: colorScheme,
              isSum: false,
              width: cellWidth,
              height: cellHeight,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Main Section: Row Headers + Left Bracket '[' + Matrix Grid N x N + Right Bracket ']' + Summary Columns OUTSIDE ]
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row Headers Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(matrixData.labels.length, (i) {
                final rowName = matrixData.labels[i];
                final isRowSelected = selectedRowIndex == i;

                return GestureDetector(
                  onTap: () => onRowHeaderTapped(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: rowHeaderWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isRowSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.4,
                            ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRowSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      rowName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isRowSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: bracketGap),

            // Left Bracket '['
            Container(
              height: matrixData.labels.length * (cellHeight + 4),
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

            // N x N Matrix Data Values Grid
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(matrixData.labels.length, (i) {
                final sourceLabel = matrixData.labels[i];
                final isRowSelected = selectedRowIndex == i;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(matrixData.labels.length, (j) {
                      final cell = matrixData.matrix[i][j];
                      final targetLabel = matrixData.labels[j];
                      final isColSelected = selectedColumnIndex == j;
                      final isIntersection = isRowSelected && isColSelected;

                      Color bg = Colors.transparent;
                      Color textColor = cell.isConnected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.4);

                      if (isIntersection) {
                        bg = colorScheme.primaryContainer;
                        textColor = colorScheme.onPrimaryContainer;
                      } else if (isColSelected) {
                        bg = colorScheme.secondaryContainer.withValues(
                          alpha: 0.35,
                        );
                      } else if (isRowSelected) {
                        bg = colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        );
                      }

                      final tooltipText =
                          'Conexión: $sourceLabel a $targetLabel\nPeso: ${cell.weightedValue}';

                      return GestureDetector(
                        onTap: () => onCellTapped(i, j),
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
                              color: bg,
                              borderRadius: BorderRadius.circular(6),
                              border: isIntersection
                                  ? Border.all(
                                      color: colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                cell.weightedValue,
                                style: TextStyle(
                                  fontWeight: cell.isConnected || isIntersection
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 15,
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

            // Right Bracket ']'
            Container(
              height: matrixData.labels.length * (cellHeight + 4),
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
              children: List.generate(matrixData.labels.length, (i) {
                final isRowSelected = selectedRowIndex == i;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Suma Fila
                      _buildSummaryCell(
                        context: context,
                        text: AdjacencyMatrixData.formatValue(
                          matrixData.rowSums[i],
                        ),
                        tooltip:
                            'Suma total de pesos para la fila ${matrixData.labels[i]}',
                        isSum: true,
                        isSelected:
                            isRowSelected ||
                            selectedColumnIndex == matrixData.labels.length,
                        colorScheme: colorScheme,
                        width: cellWidth,
                        height: cellHeight,
                      ),
                      // Grado Fila
                      _buildSummaryCell(
                        context: context,
                        text: '${matrixData.rowDegrees[i]}',
                        tooltip:
                            'Grado / Conexiones activas de la fila ${matrixData.labels[i]}',
                        isSum: false,
                        isSelected:
                            isRowSelected ||
                            selectedColumnIndex == matrixData.labels.length + 1,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderCell(
              context: context,
              label: 'Suma Col.',
              isSelected: selectedRowIndex == matrixData.labels.length,
              onTap: () => onRowSummaryHeaderTapped(matrixData.labels.length),
              colorScheme: colorScheme,
              isSum: true,
              width: rowHeaderWidth,
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            ...List.generate(matrixData.labels.length, (j) {
              final isColSelected = selectedColumnIndex == j;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSummaryCell(
                  context: context,
                  text: AdjacencyMatrixData.formatValue(matrixData.colSums[j]),
                  tooltip:
                      'Suma total de pesos para la columna ${matrixData.labels[j]}',
                  isSum: true,
                  isSelected:
                      isColSelected ||
                      selectedRowIndex == matrixData.labels.length,
                  colorScheme: colorScheme,
                  width: cellWidth,
                  height: cellHeight,
                ),
              );
            }),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderCell(
              context: context,
              label: 'Grado Col.',
              isSelected: selectedRowIndex == matrixData.labels.length + 1,
              onTap: () =>
                  onRowSummaryHeaderTapped(matrixData.labels.length + 1),
              colorScheme: colorScheme,
              isSum: false,
              width: rowHeaderWidth,
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            ...List.generate(matrixData.labels.length, (j) {
              final isColSelected = selectedColumnIndex == j;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSummaryCell(
                  context: context,
                  text: '${matrixData.colDegrees[j]}',
                  tooltip:
                      'Grado / Conexiones activas de la columna ${matrixData.labels[j]}',
                  isSum: false,
                  isSelected:
                      isColSelected ||
                      selectedRowIndex == matrixData.labels.length + 1,
                  colorScheme: colorScheme,
                  width: cellWidth,
                  height: cellHeight,
                ),
              );
            }),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
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
  }) {
    final baseColor = isSum ? colorScheme.primary : colorScheme.secondary;
    final baseContainer = isSum
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;

    final bgColor = isSelected
        ? baseContainer
        : baseContainer.withValues(alpha: 0.3);
    final borderColor = isSelected
        ? baseColor
        : baseColor.withValues(alpha: 0.4);
    final textColor = isSelected
        ? (isSum
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSecondaryContainer)
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
  }) {
    final baseColor = isSum ? colorScheme.primary : colorScheme.secondary;
    final baseContainer = isSum
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;

    final bg = isSelected
        ? baseContainer
        : baseContainer.withValues(alpha: 0.2);
    final textColor = isSelected
        ? (isSum
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSecondaryContainer)
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
