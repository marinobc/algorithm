import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../providers/assignment_provider.dart';

/// Screen displaying the dedicated Bipartite Matrix (Origins x Destinations)
/// for the Assignment / Hungarian Algorithm.
class AssignmentBipartiteMatrixScreen extends ConsumerStatefulWidget {
  const AssignmentBipartiteMatrixScreen({super.key});

  @override
  ConsumerState<AssignmentBipartiteMatrixScreen> createState() =>
      _AssignmentBipartiteMatrixScreenState();
}

class _AssignmentBipartiteMatrixScreenState
    extends ConsumerState<AssignmentBipartiteMatrixScreen> {
  int? _selectedRowIndex;
  int? _selectedColumnIndex;

  static const double cellWidth = 84.0;
  static const double cellHeight = 52.0;
  static const double rowHeaderWidth = 90.0;
  static const double bracketWidth = 14.0;
  static const double bracketGap = 10.0;

  static const double totalLeftOffset =
      rowHeaderWidth + bracketGap + bracketWidth + bracketGap;

  double? _getConnectionWeight(Grafo grafo, String origId, String destId) {
    Conexion? matchingCon;
    for (final c in grafo.conexiones.values) {
      if (c.nodoOrigenId == origId && c.nodoDestinoId == destId) {
        matchingCon = c;
        break;
      }
    }
    if (matchingCon == null) return null;

    final pesoAttr = matchingCon.atributos.firstWhere(
      (a) =>
          a.atributoId == 'attr_valor' ||
          a.atributoId.toLowerCase().contains('cost') ||
          a.atributoId.toLowerCase().contains('peso') ||
          a.atributoId.toLowerCase().contains('valor'),
      orElse: () => matchingCon!.atributos.isNotEmpty
          ? matchingCon.atributos.first
          : const AtributoValor(atributoId: '', valor: '1'),
    );

    final numVal = double.tryParse(pesoAttr.valor);
    return numVal ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grafo = ref.watch(grafoProvider);
    final validation = ref.watch(transportationValidationProvider);

    final origins = validation.origins;
    final destinations = validation.destinations;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matriz de Costos de Asignación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Bipartita: Orígenes (Filas) × Destinos (Columnas)',
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
        child: !validation.isValid
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Grafo de Asignación incompleto o inválido',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        validation.errorMessage ?? 'Configure nodos de origen y destino conectados para ver la matriz de asignación.',
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
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Main Matrix Card
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
                                  child: _buildBipartiteGrid(
                                    context: context,
                                    grafo: grafo,
                                    origins: origins,
                                    destinations: destinations,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBipartiteGrid({
    required BuildContext context,
    required Grafo grafo,
    required List<Nodo> origins,
    required List<Nodo> destinations,
    required ColorScheme colorScheme,
  }) {
    // 1. Calculate row sums and degrees (Origins)
    final rowSums = <double>[];
    final rowDegrees = <int>[];
    for (final orig in origins) {
      double sum = 0.0;
      int deg = 0;
      for (final dest in destinations) {
        final w = _getConnectionWeight(grafo, orig.id, dest.id);
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
    for (final dest in destinations) {
      double sum = 0.0;
      int deg = 0;
      for (final orig in origins) {
        final w = _getConnectionWeight(grafo, orig.id, dest.id);
        if (w != null) {
          sum += w;
          deg += 1;
        }
      }
      colSums.add(sum);
      colDegrees.add(deg);
    }

    final matrixHeight = origins.length * (cellHeight + 4);

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
            ...List.generate(destinations.length, (j) {
              final isColSelected = _selectedColumnIndex == j;
              final destNode = destinations[j];
              final label = destNode.nombre ?? destNode.id;

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
              isSelected: _selectedColumnIndex == destinations.length,
              onTap: () {
                setState(() {
                  _selectedColumnIndex =
                      _selectedColumnIndex == destinations.length
                      ? null
                      : destinations.length;
                });
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
              isSelected: _selectedColumnIndex == destinations.length + 1,
              onTap: () {
                setState(() {
                  _selectedColumnIndex =
                      _selectedColumnIndex == destinations.length + 1
                      ? null
                      : destinations.length + 1;
                });
              },
              colorScheme: colorScheme,
              isSum: false,
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
              children: List.generate(origins.length, (i) {
                final isRowSelected = _selectedRowIndex == i;
                final origNode = origins[i];
                final label = origNode.nombre ?? origNode.id;

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
              children: List.generate(origins.length, (i) {
                final origNode = origins[i];
                final isRowSelected = _selectedRowIndex == i;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(destinations.length, (j) {
                      final destNode = destinations[j];
                      final weight = _getConnectionWeight(
                        grafo,
                        origNode.id,
                        destNode.id,
                      );

                      final isColSelected = _selectedColumnIndex == j;
                      final isCellSelected =
                          _selectedRowIndex == i && _selectedColumnIndex == j;
                      final isHighlighted = isRowSelected || isColSelected;

                      final hasConnection = weight != null;
                      final cellText = hasConnection
                          ? (weight % 1 == 0
                                ? weight.toInt().toString()
                                : weight.toStringAsFixed(1))
                          : '—';

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
                          setState(() {
                            if (_selectedRowIndex == i &&
                                _selectedColumnIndex == j) {
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
              children: List.generate(origins.length, (i) {
                final isRowSelected = _selectedRowIndex == i;
                final origNode = origins[i];
                final origLabel = origNode.nombre ?? origNode.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Suma Fila
                      _buildSummaryCell(
                        context: context,
                        text: _formatVal(rowSums[i]),
                        tooltip:
                            'Suma total de costos para el origen $origLabel',
                        isSum: true,
                        isSelected:
                            isRowSelected ||
                            _selectedColumnIndex == destinations.length,
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
                            _selectedColumnIndex == destinations.length + 1,
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
              isSelected: _selectedRowIndex == origins.length,
              onTap: () {
                setState(() {
                  _selectedRowIndex = _selectedRowIndex == origins.length
                      ? null
                      : origins.length;
                });
              },
              colorScheme: colorScheme,
              isSum: true,
              width: rowHeaderWidth,
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            ...List.generate(destinations.length, (j) {
              final isColSelected = _selectedColumnIndex == j;
              final destNode = destinations[j];
              final destLabel = destNode.nombre ?? destNode.id;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSummaryCell(
                  context: context,
                  text: _formatVal(colSums[j]),
                  tooltip: 'Suma total de costos para el destino $destLabel',
                  isSum: true,
                  isSelected:
                      isColSelected || _selectedRowIndex == origins.length,
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
              isSelected: _selectedRowIndex == origins.length + 1,
              onTap: () {
                setState(() {
                  _selectedRowIndex = _selectedRowIndex == origins.length + 1
                      ? null
                      : origins.length + 1;
                });
              },
              colorScheme: colorScheme,
              isSum: false,
              width: rowHeaderWidth,
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(width: bracketGap + bracketWidth + bracketGap),
            ...List.generate(destinations.length, (j) {
              final isColSelected = _selectedColumnIndex == j;
              final destNode = destinations[j];
              final destLabel = destNode.nombre ?? destNode.id;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSummaryCell(
                  context: context,
                  text: '${colDegrees[j]}',
                  tooltip: 'Conexiones recibidas por el destino $destLabel',
                  isSum: false,
                  isSelected:
                      isColSelected || _selectedRowIndex == origins.length + 1,
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

  static String _formatVal(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
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
