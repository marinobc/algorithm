import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/adjacency_matrix_service.dart';

typedef AdjacencyMatrixDialog = AdjacencyMatrixScreen;

class AdjacencyMatrixScreen extends ConsumerStatefulWidget {
  const AdjacencyMatrixScreen({super.key});

  @override
  ConsumerState<AdjacencyMatrixScreen> createState() =>
      _AdjacencyMatrixScreenState();
}

class _AdjacencyMatrixScreenState extends ConsumerState<AdjacencyMatrixScreen> {
  int? _selectedRowIndex;
  int? _selectedColumnIndex;

  @override
  Widget build(BuildContext context) {
    final grafo = ref.watch(grafoProvider);
    final esInvalido = ref.watch(esGrafoInvalidoProvider);
    final matrixData = AdjacencyMatrixService.calculateMatrix(grafo);
    final colorScheme = Theme.of(context).colorScheme;

    const double cellWidth = 76.0;
    const double cellHeight = 52.0;
    const double rowHeaderWidth = 76.0;
    const double bracketWidth = 14.0;
    const double bracketGap = 12.0;

    const double totalLeftOffset =
        rowHeaderWidth + bracketGap + bracketWidth + bracketGap;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matriz de Adyacencia Ponderada',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Toca para resaltar el fondo',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: esInvalido
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 64,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Conecta el grafo para poder ver la matriz',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Existen nodos o secciones sin conectar en el lienzo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : matrixData.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_off_rounded,
                      size: 64,
                      color: colorScheme.outline.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'El lienzo está vacío',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agrega nodos y conexiones en el lienzo para calcular la matriz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Main Mathematical Matrix Card Container
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Top Row: Column Headers (Node Headers aligned with Matrix; Summary Headers aligned outside ])
                                      Row(
                                        children: [
                                          // Offset to align with matrix columns inside [ ]
                                          const SizedBox(width: totalLeftOffset),
                                          // Standard Node Headers
                                          ...List.generate(matrixData.labels.length, (j) {
                                            final colName = matrixData.labels[j];
                                            final isColSelected = _selectedColumnIndex == j;

                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedColumnIndex = isColSelected ? null : j;
                                                });
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
                                                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                                          // Gap over Right Bracket ']'
                                          const SizedBox(width: bracketGap + bracketWidth + bracketGap),
                                          // Extra Summary Header 1: Suma Fila
                                          _buildHeaderCell(
                                            context: context,
                                            label: 'Suma Fila',
                                            isSelected: _selectedColumnIndex == matrixData.labels.length,
                                            onTap: () {
                                              setState(() {
                                                _selectedColumnIndex = _selectedColumnIndex == matrixData.labels.length
                                                    ? null
                                                    : matrixData.labels.length;
                                              });
                                            },
                                            colorScheme: colorScheme,
                                            isSum: true,
                                            width: cellWidth,
                                            height: cellHeight,
                                          ),
                                          // Extra Summary Header 2: Grado Fila
                                          _buildHeaderCell(
                                            context: context,
                                            label: 'Grado Fila',
                                            isSelected: _selectedColumnIndex == matrixData.labels.length + 1,
                                            onTap: () {
                                              setState(() {
                                                _selectedColumnIndex = _selectedColumnIndex == matrixData.labels.length + 1
                                                    ? null
                                                    : matrixData.labels.length + 1;
                                              });
                                            },
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
                                          // Row Headers Column (Node Names OUTSIDE Brackets)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(matrixData.labels.length, (i) {
                                              final rowName = matrixData.labels[i];
                                              final isRowSelected = _selectedRowIndex == i;

                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedRowIndex = isRowSelected ? null : i;
                                                  });
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  width: rowHeaderWidth,
                                                  height: cellHeight,
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isRowSelected
                                                        ? colorScheme.primaryContainer
                                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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

                                          // Large Mathematical Left Bracket '[' (Spans only N node rows)
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

                                          // N x N Matrix Data Values Grid (Inside Brackets)
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(matrixData.labels.length, (i) {
                                              final sourceLabel = matrixData.labels[i];
                                              final isRowSelected = _selectedRowIndex == i;

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: List.generate(matrixData.labels.length, (j) {
                                                    final cell = matrixData.matrix[i][j];
                                                    final targetLabel = matrixData.labels[j];
                                                    final isColSelected = _selectedColumnIndex == j;
                                                    final isIntersection = isRowSelected && isColSelected;

                                                    Color bg = Colors.transparent;
                                                    Color textColor = cell.isConnected
                                                        ? colorScheme.primary
                                                        : colorScheme.outline.withValues(alpha: 0.4);

                                                    if (isIntersection) {
                                                      bg = colorScheme.primaryContainer;
                                                      textColor = colorScheme.onPrimaryContainer;
                                                    } else if (isColSelected) {
                                                      bg = colorScheme.secondaryContainer.withValues(alpha: 0.35);
                                                    } else if (isRowSelected) {
                                                      bg = colorScheme.primaryContainer.withValues(alpha: 0.35);
                                                    }

                                                    final tooltipText = 'Conexión: $sourceLabel a $targetLabel\nPeso: ${cell.weightedValue}';

                                                    return GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          if (_selectedRowIndex == i && _selectedColumnIndex == j) {
                                                            _selectedRowIndex = null;
                                                            _selectedColumnIndex = null;
                                                          } else {
                                                            _selectedRowIndex = i;
                                                            _selectedColumnIndex = j;
                                                          }
                                                        });
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
                                                            color: bg,
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: isIntersection
                                                                ? Border.all(color: colorScheme.primary, width: 2)
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

                                          // Large Mathematical Right Bracket ']' (Spans only N node rows)
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
                                              final isRowSelected = _selectedRowIndex == i;

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Suma Fila
                                                    _buildSummaryCell(
                                                      context: context,
                                                      text: AdjacencyMatrixData.formatValue(matrixData.rowSums[i]),
                                                      tooltip: 'Suma total de pesos para la fila ${matrixData.labels[i]}',
                                                      isSum: true,
                                                      isSelected: isRowSelected || _selectedColumnIndex == matrixData.labels.length,
                                                      colorScheme: colorScheme,
                                                      width: cellWidth,
                                                      height: cellHeight,
                                                    ),
                                                    // Grado Fila
                                                    _buildSummaryCell(
                                                      context: context,
                                                      text: '${matrixData.rowDegrees[i]}',
                                                      tooltip: 'Grado / Conexiones activas de la fila ${matrixData.labels[i]}',
                                                      isSum: false,
                                                      isSelected: isRowSelected || _selectedColumnIndex == matrixData.labels.length + 1,
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
                                      // Summary Row 1: Suma Col.
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildHeaderCell(
                                            context: context,
                                            label: 'Suma Col.',
                                            isSelected: _selectedRowIndex == matrixData.labels.length,
                                            onTap: () {
                                              setState(() {
                                                _selectedRowIndex = _selectedRowIndex == matrixData.labels.length
                                                    ? null
                                                    : matrixData.labels.length;
                                              });
                                            },
                                            colorScheme: colorScheme,
                                            isSum: true,
                                            width: rowHeaderWidth,
                                            height: cellHeight,
                                            margin: const EdgeInsets.symmetric(vertical: 2),
                                          ),
                                          // Gap under Left Bracket '['
                                          const SizedBox(width: bracketGap + bracketWidth + bracketGap),
                                          // Column Sums for N nodes
                                          ...List.generate(matrixData.labels.length, (j) {
                                            final isColSelected = _selectedColumnIndex == j;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: _buildSummaryCell(
                                                context: context,
                                                text: AdjacencyMatrixData.formatValue(matrixData.colSums[j]),
                                                tooltip: 'Suma total de pesos para la columna ${matrixData.labels[j]}',
                                                isSum: true,
                                                isSelected: isColSelected || _selectedRowIndex == matrixData.labels.length,
                                                colorScheme: colorScheme,
                                                width: cellWidth,
                                                height: cellHeight,
                                              ),
                                            );
                                          }),
                                          // Gap under Right Bracket ']'
                                          const SizedBox(width: bracketGap + bracketWidth + bracketGap),
                                        ],
                                      ),
                                      // Summary Row 2: Grado Col.
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildHeaderCell(
                                            context: context,
                                            label: 'Grado Col.',
                                            isSelected: _selectedRowIndex == matrixData.labels.length + 1,
                                            onTap: () {
                                              setState(() {
                                                _selectedRowIndex = _selectedRowIndex == matrixData.labels.length + 1
                                                    ? null
                                                    : matrixData.labels.length + 1;
                                              });
                                            },
                                            colorScheme: colorScheme,
                                            isSum: false,
                                            width: rowHeaderWidth,
                                            height: cellHeight,
                                            margin: const EdgeInsets.symmetric(vertical: 2),
                                          ),
                                          // Gap under Left Bracket '['
                                          const SizedBox(width: bracketGap + bracketWidth + bracketGap),
                                          // Column Degrees for N nodes
                                          ...List.generate(matrixData.labels.length, (j) {
                                            final isColSelected = _selectedColumnIndex == j;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: _buildSummaryCell(
                                                context: context,
                                                text: '${matrixData.colDegrees[j]}',
                                                tooltip: 'Grado / Conexiones activas de la columna ${matrixData.labels[j]}',
                                                isSum: false,
                                                isSelected: isColSelected || _selectedRowIndex == matrixData.labels.length + 1,
                                                colorScheme: colorScheme,
                                                width: cellWidth,
                                                height: cellHeight,
                                              ),
                                            );
                                          }),
                                          // Gap under Right Bracket ']'
                                          const SizedBox(width: bracketGap + bracketWidth + bracketGap),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Data at Bottom (3 Cards, One Card Per Row)
                    Column(
                      children: [
                        // Card 1 (Row 1): Nodos Stats
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: colorScheme.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hub_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Total de Nodos: ${matrixData.nodes.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Card 2 (Row 2): Conexiones Stats
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: colorScheme.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.alt_route_rounded,
                                  color: colorScheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Total de Conexiones: ${grafo.conexiones.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Card 3 (Row 3): Grado del Grafo (Graph Degree Single Metric)
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: colorScheme.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bar_chart_rounded,
                                      color: colorScheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Δ(G) = ${matrixData.maxDegree}   δ(G) = ${matrixData.minDegree}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedRowIndex != null ||
                                    _selectedColumnIndex != null)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedRowIndex = null;
                                        _selectedColumnIndex = null;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Limpiar Selección',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
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
    final baseContainer = isSum ? colorScheme.primaryContainer : colorScheme.secondaryContainer;

    final bgColor = isSelected
        ? baseContainer
        : baseContainer.withValues(alpha: 0.3);

    final borderColor = isSelected
        ? baseColor
        : baseColor.withValues(alpha: 0.4);

    final textColor = isSelected
        ? (isSum ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer)
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
    final baseContainer = isSum ? colorScheme.primaryContainer : colorScheme.secondaryContainer;

    final bg = isSelected
        ? baseContainer
        : baseContainer.withValues(alpha: 0.2);

    final textColor = isSelected
        ? (isSum ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer)
        : baseColor;

    return Tooltip(
      message: tooltip,
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
