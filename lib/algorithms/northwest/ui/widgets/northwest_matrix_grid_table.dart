import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/widgets/matrix/matrix_input_widgets.dart';

class NorthwestMatrixGridTable extends StatelessWidget {
  final List<TextEditingController> originNames;
  final List<TextEditingController> destinationNames;
  final List<FocusNode> originFocusNodes;
  final List<FocusNode> destinationFocusNodes;
  final List<TextEditingController> supplies;
  final List<TextEditingController> demands;
  final List<FocusNode> supplyFocusNodes;
  final List<FocusNode> demandFocusNodes;
  final List<List<TextEditingController>> costs;
  final List<List<FocusNode>> cellFocusNodes;
  final List<String> originIds;
  final List<String> destinationIds;
  final bool Function(int i) isOriginFictitiousFn;
  final bool Function(int j) isDestFictitiousFn;
  final bool Function(int i, int j) isCellFictitiousFn;

  const NorthwestMatrixGridTable({
    super.key,
    required this.originNames,
    required this.destinationNames,
    required this.originFocusNodes,
    required this.destinationFocusNodes,
    required this.supplies,
    required this.demands,
    required this.supplyFocusNodes,
    required this.demandFocusNodes,
    required this.costs,
    required this.cellFocusNodes,
    required this.originIds,
    required this.destinationIds,
    required this.isOriginFictitiousFn,
    required this.isDestFictitiousFn,
    required this.isCellFictitiousFn,
  });

  static const _dummyOriginId = 'nw_dummy_origin';
  static const _dummyDestinationId = 'nw_dummy_destination';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final columns = <DataColumn>[
      DataColumn(
        label: Text(
          'Origen / Destino',
          style: TextStyle(
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...List.generate(destinationNames.length, (j) {
        final name = destinationNames[j].text.trim();
        final destId = j < destinationIds.length ? destinationIds[j] : '';
        final isFictitious =
            destId == _dummyDestinationId ||
            name == 'Ficticio' ||
            name.startsWith('Ficticio ');
        return DataColumn(
          label: SizedBox(
            width: 80,
            child: MouseRegion(
              cursor: isFictitious
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.text,
              child: Focus(
                canRequestFocus: !isFictitious,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    final key = event.logicalKey;
                    if (key == LogicalKeyboardKey.arrowDown) {
                      var r = 0;
                      while (r < originNames.length &&
                          isCellFictitiousFn(r, j)) {
                        r++;
                      }
                      if (r < originNames.length) {
                        cellFocusNodes[r][j].requestFocus();
                      }
                      return KeyEventResult.handled;
                    } else if (key == LogicalKeyboardKey.arrowLeft && j > 0) {
                      var c = j - 1;
                      while (c >= 0 && isDestFictitiousFn(c)) {
                        c--;
                      }
                      if (c >= 0) {
                        destinationFocusNodes[c].requestFocus();
                      }
                      return KeyEventResult.handled;
                    } else if (key == LogicalKeyboardKey.arrowRight &&
                        j < destinationNames.length - 1) {
                      var c = j + 1;
                      while (c < destinationNames.length &&
                          isDestFictitiousFn(c)) {
                        c++;
                      }
                      if (c < destinationNames.length) {
                        destinationFocusNodes[c].requestFocus();
                      }
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final hasFocus = Focus.of(context).hasFocus;
                    return TextField(
                      controller: destinationNames[j],
                      focusNode: destinationFocusNodes[j],
                      readOnly: isFictitious,
                      enabled: !isFictitious,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isFictitious
                            ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                            : colors.onSecondaryContainer,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hasFocus ? '' : 'Destino ${j + 1}',
                        hintStyle: TextStyle(
                          color: colors.onSecondaryContainer.withValues(
                            alpha: 0.38,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        fillColor: isFictitious
                            ? colors.surfaceContainerHighest.withValues(
                                alpha: 0.75,
                              )
                            : colors.secondaryContainer.withValues(alpha: 0.5),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      onTap: () {
                        if (!isFictitious &&
                            destinationNames[j].text.isNotEmpty) {
                          destinationNames[j].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: destinationNames[j].text.length,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }),
      DataColumn(
        label: Text(
          'Disponibilidad (aᵢ)',
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];

    final rows = <DataRow>[
      ...List.generate(originNames.length, (i) {
        final originName = originNames[i].text.trim();
        final originId = i < originIds.length ? originIds[i] : '';
        final isOriginFictitious =
            originId == _dummyOriginId ||
            originName == 'Ficticio' ||
            originName.startsWith('Ficticio ');
        return DataRow(
          color: isOriginFictitious
              ? WidgetStatePropertyAll(
                  colors.surfaceContainerHighest.withValues(alpha: 0.35),
                )
              : null,
          cells: [
            DataCell(
              SizedBox(
                width: 90,
                child: MouseRegion(
                  cursor: isOriginFictitious
                      ? SystemMouseCursors.forbidden
                      : SystemMouseCursors.text,
                  child: Focus(
                    canRequestFocus: !isOriginFictitious,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final key = event.logicalKey;
                        if (key == LogicalKeyboardKey.arrowUp && i > 0) {
                          var r = i - 1;
                          while (r >= 0 && isOriginFictitiousFn(r)) {
                            r--;
                          }
                          if (r >= 0) {
                            originFocusNodes[r].requestFocus();
                          }
                          return KeyEventResult.handled;
                        } else if (key == LogicalKeyboardKey.arrowDown &&
                            i < originNames.length - 1) {
                          var r = i + 1;
                          while (r < originNames.length &&
                              isOriginFictitiousFn(r)) {
                            r++;
                          }
                          if (r < originNames.length) {
                            originFocusNodes[r].requestFocus();
                          }
                          return KeyEventResult.handled;
                        } else if (key == LogicalKeyboardKey.arrowRight &&
                            destinationNames.isNotEmpty) {
                          var c = 0;
                          while (c < destinationNames.length &&
                              isCellFictitiousFn(i, c)) {
                            c++;
                          }
                          if (c < destinationNames.length) {
                            cellFocusNodes[i][c].requestFocus();
                          }
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final hasFocus = Focus.of(context).hasFocus;
                        return TextField(
                          controller: originNames[i],
                          focusNode: originFocusNodes[i],
                          readOnly: isOriginFictitious,
                          enabled: !isOriginFictitious,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isOriginFictitious
                                ? colors.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  )
                                : colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: hasFocus ? '' : 'Origen ${i + 1}',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.38,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            fillColor: isOriginFictitious
                                ? colors.surfaceContainerHighest.withValues(
                                    alpha: 0.75,
                                  )
                                : colors.secondaryContainer.withValues(
                                    alpha: 0.3,
                                  ),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            if (!isOriginFictitious &&
                                originNames[i].text.isNotEmpty) {
                              originNames[i].selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: originNames[i].text.length,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(destinationNames.length, (j) {
              final destName = destinationNames[j].text.trim();
              final destId = j < destinationIds.length ? destinationIds[j] : '';
              final isDestFictitious =
                  destId == _dummyDestinationId ||
                  destName == 'Ficticio' ||
                  destName.startsWith('Ficticio ');
              final isCellFictitiousVal =
                  isOriginFictitious || isDestFictitious;
              return DataCell(
                MatrixCellInput(
                  controller: costs[i][j],
                  focusNode: cellFocusNodes[i][j],
                  hint: 'Costo',
                  readOnly: isCellFictitiousVal,
                  rowIndex: i,
                  colIndex: j,
                  totalRows: originNames.length + 1,
                  totalCols: destinationNames.length + 1,
                  onNavigate: (targetRow, targetCol) {
                    final dr = targetRow > i ? 1 : (targetRow < i ? -1 : 0);
                    final dc = targetCol > j ? 1 : (targetCol < j ? -1 : 0);
                    var r = targetRow;
                    var c = targetCol;

                    while (r >= 0 &&
                        r < originNames.length &&
                        c >= 0 &&
                        c < destinationNames.length) {
                      if (!isCellFictitiousFn(r, c)) {
                        cellFocusNodes[r][c].requestFocus();
                        return;
                      }
                      if (dr == 0 && dc == 0) break;
                      r += dr;
                      c += dc;
                    }

                    if (c == destinationNames.length && dr == 0 && dc == 1) {
                      var supplyR = i;
                      while (supplyR >= 0 && isOriginFictitiousFn(supplyR)) {
                        supplyR--;
                      }
                      if (supplyR >= 0) {
                        supplyFocusNodes[supplyR].requestFocus();
                      }
                    } else if (r == originNames.length && dr == 1 && dc == 0) {
                      var demandC = j;
                      while (demandC >= 0 && isDestFictitiousFn(demandC)) {
                        demandC--;
                      }
                      if (demandC >= 0) {
                        demandFocusNodes[demandC].requestFocus();
                      }
                    } else if (c == -1 && dr == 0 && dc == -1) {
                      var origR = i;
                      while (origR >= 0 && isOriginFictitiousFn(origR)) {
                        origR--;
                      }
                      if (origR >= 0) {
                        originFocusNodes[origR].requestFocus();
                      }
                    } else if (r == -1 && dr == -1 && dc == 0) {
                      var destC = j;
                      while (destC >= 0 && isDestFictitiousFn(destC)) {
                        destC--;
                      }
                      if (destC >= 0) {
                        destinationFocusNodes[destC].requestFocus();
                      }
                    }
                  },
                ),
              );
            }),
            DataCell(
              MatrixCellInput(
                controller: supplies[i],
                focusNode: supplyFocusNodes[i],
                hint: 'Disp',
                isHighlight: true,
                readOnly: isOriginFictitious,
                rowIndex: i,
                colIndex: destinationNames.length,
                totalRows: originNames.length,
                totalCols: destinationNames.length + 1,
                onNavigate: (targetRow, targetCol) {
                  if (targetCol < destinationNames.length) {
                    var c = destinationNames.length - 1;
                    while (c >= 0 && isCellFictitiousFn(i, c)) {
                      c--;
                    }
                    if (c >= 0) {
                      cellFocusNodes[i][c].requestFocus();
                    }
                  } else {
                    final dr = targetRow > i ? 1 : (targetRow < i ? -1 : 0);
                    var r = targetRow;
                    while (r >= 0 && r < originNames.length) {
                      if (!isOriginFictitiousFn(r)) {
                        supplyFocusNodes[r].requestFocus();
                        return;
                      }
                      if (dr == 0) break;
                      r += dr;
                    }
                  }
                },
              ),
            ),
          ],
        );
      }),
      DataRow(
        color: WidgetStatePropertyAll(
          colors.primaryContainer.withValues(alpha: 0.4),
        ),
        cells: [
          DataCell(
            Text(
              'Demanda (bⱼ)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          ...List.generate(destinationNames.length, (j) {
            final destName = destinationNames[j].text.trim();
            final isDestFictitious =
                destName == 'Ficticio' || destName.startsWith('Ficticio ');
            return DataCell(
              MatrixCellInput(
                controller: demands[j],
                focusNode: demandFocusNodes[j],
                hint: 'Demanda',
                isHighlight: true,
                readOnly: isDestFictitious,
                rowIndex: originNames.length,
                colIndex: j,
                totalRows: originNames.length + 1,
                totalCols: destinationNames.length,
                onNavigate: (targetRow, targetCol) {
                  if (targetRow < originNames.length) {
                    var r = originNames.length - 1;
                    while (r >= 0 && isCellFictitiousFn(r, j)) {
                      r--;
                    }
                    if (r >= 0) {
                      cellFocusNodes[r][j].requestFocus();
                    }
                  } else {
                    final dc = targetCol > j ? 1 : (targetCol < j ? -1 : 0);
                    var c = targetCol;
                    while (c >= 0 && c < destinationNames.length) {
                      if (!isDestFictitiousFn(c)) {
                        demandFocusNodes[c].requestFocus();
                        return;
                      }
                      if (dc == 0) break;
                      c += dc;
                    }
                  }
                },
              ),
            );
          }),
          const DataCell(SizedBox.shrink()),
        ],
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DataTable(
        clipBehavior: Clip.antiAlias,
        headingRowColor: WidgetStatePropertyAll(colors.secondaryContainer),
        dataRowMaxHeight: 52,
        dataRowMinHeight: 48,
        horizontalMargin: 12,
        columnSpacing: 12,
        columns: columns,
        rows: rows,
      ),
    );
  }
}
