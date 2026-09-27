import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/widgets/matrix/bipartite_matrix_config.dart';
import '../../../../ui/widgets/matrix/matrix_input_widgets.dart';

class AssignmentMatrixGridTable extends StatelessWidget {
  final BipartiteMatrixConfig config;
  final List<TextEditingController> originNames;
  final List<TextEditingController> destinationNames;
  final List<FocusNode> originFocusNodes;
  final List<FocusNode> destinationFocusNodes;
  final List<List<TextEditingController>> costs;
  final List<List<FocusNode>> cellFocusNodes;
  final List<String> originIds;
  final List<String> destinationIds;

  const AssignmentMatrixGridTable({
    super.key,
    required this.config,
    required this.originNames,
    required this.destinationNames,
    required this.originFocusNodes,
    required this.destinationFocusNodes,
    required this.costs,
    required this.cellFocusNodes,
    required this.originIds,
    required this.destinationIds,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final columns = <DataColumn>[
      DataColumn(
        label: Text(
          config.originHeaderTitle,
          style: TextStyle(
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...List.generate(destinationNames.length, (j) {
        final isFicticioCol =
            destinationNames[j].text.trim().toLowerCase().startsWith(
              'ficticio',
            ) ||
            destinationIds[j].contains('_dummy_');
        return DataColumn(
          label: SizedBox(
            width: 80,
            child: Focus(
              canRequestFocus: !isFicticioCol,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.arrowDown &&
                      originNames.isNotEmpty) {
                    var targetRow = 0;
                    while (targetRow < originNames.length &&
                        (originNames[targetRow].text
                                .trim()
                                .toLowerCase()
                                .startsWith('ficticio') ||
                            originIds[targetRow].contains('_dummy_'))) {
                      targetRow++;
                    }
                    if (targetRow < originNames.length) {
                      cellFocusNodes[targetRow][j].requestFocus();
                    }
                    return KeyEventResult.handled;
                  } else if (key == LogicalKeyboardKey.arrowLeft && j > 0) {
                    var targetCol = j - 1;
                    while (targetCol >= 0 &&
                        (destinationNames[targetCol].text
                                .trim()
                                .toLowerCase()
                                .startsWith('ficticio') ||
                            destinationIds[targetCol].contains('_dummy_'))) {
                      targetCol--;
                    }
                    if (targetCol >= 0) {
                      destinationFocusNodes[targetCol].requestFocus();
                    }
                    return KeyEventResult.handled;
                  } else if (key == LogicalKeyboardKey.arrowRight &&
                      j < destinationNames.length - 1) {
                    var targetCol = j + 1;
                    while (targetCol < destinationNames.length &&
                        (destinationNames[targetCol].text
                                .trim()
                                .toLowerCase()
                                .startsWith('ficticio') ||
                            destinationIds[targetCol].contains('_dummy_'))) {
                      targetCol++;
                    }
                    if (targetCol < destinationNames.length) {
                      destinationFocusNodes[targetCol].requestFocus();
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
                    readOnly: isFicticioCol,
                    enabled: !isFicticioCol,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isFicticioCol
                          ? colors.onSecondaryContainer.withValues(alpha: 0.4)
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
                      fillColor: colors.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onTap: () {
                      if (!isFicticioCol &&
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
        );
      }),
    ];

    final rows = <DataRow>[
      ...List.generate(originNames.length, (i) {
        final isFicticioRow =
            originNames[i].text.trim().toLowerCase().startsWith('ficticio') ||
            originIds[i].contains('_dummy_');
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 90,
                child: Focus(
                  canRequestFocus: !isFicticioRow,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final key = event.logicalKey;
                      if (key == LogicalKeyboardKey.arrowUp && i > 0) {
                        var targetRow = i - 1;
                        while (targetRow >= 0 &&
                            (originNames[targetRow].text
                                    .trim()
                                    .toLowerCase()
                                    .startsWith('ficticio') ||
                                originIds[targetRow].contains('_dummy_'))) {
                          targetRow--;
                        }
                        if (targetRow >= 0) {
                          originFocusNodes[targetRow].requestFocus();
                        }
                        return KeyEventResult.handled;
                      } else if (key == LogicalKeyboardKey.arrowDown &&
                          i < originNames.length - 1) {
                        var targetRow = i + 1;
                        while (targetRow < originNames.length &&
                            (originNames[targetRow].text
                                    .trim()
                                    .toLowerCase()
                                    .startsWith('ficticio') ||
                                originIds[targetRow].contains('_dummy_'))) {
                          targetRow++;
                        }
                        if (targetRow < originNames.length) {
                          originFocusNodes[targetRow].requestFocus();
                        }
                        return KeyEventResult.handled;
                      } else if (key == LogicalKeyboardKey.arrowRight &&
                          destinationNames.isNotEmpty) {
                        var targetCol = 0;
                        while (targetCol < destinationNames.length &&
                            (destinationNames[targetCol].text
                                    .trim()
                                    .toLowerCase()
                                    .startsWith('ficticio') ||
                                destinationIds[targetCol].contains(
                                  '_dummy_',
                                ))) {
                          targetCol++;
                        }
                        if (targetCol < destinationNames.length) {
                          cellFocusNodes[i][targetCol].requestFocus();
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
                        readOnly: isFicticioRow,
                        enabled: !isFicticioRow,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isFicticioRow
                              ? colors.onSurface.withValues(alpha: 0.4)
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
                          fillColor: colors.secondaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onTap: () {
                          if (!isFicticioRow &&
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
            ...List.generate(destinationNames.length, (j) {
              final isRowFicticio =
                  originNames[i].text.trim().toLowerCase().startsWith(
                    'ficticio',
                  ) ||
                  originIds[i].contains('_dummy_');
              final isColFicticio =
                  destinationNames[j].text.trim().toLowerCase().startsWith(
                    'ficticio',
                  ) ||
                  destinationIds[j].contains('_dummy_');
              final isCellFicticio = isRowFicticio || isColFicticio;

              return DataCell(
                MatrixCellInput(
                  controller: costs[i][j],
                  focusNode: cellFocusNodes[i][j],
                  readOnly: isCellFicticio,
                  hint: config.costCellHint,
                  rowIndex: i,
                  colIndex: j,
                  totalRows: originNames.length,
                  totalCols: destinationNames.length,
                  onNavigate: (targetRow, targetCol) {
                    if (targetRow == -1 && targetCol >= 0) {
                      var c = targetCol;
                      while (c >= 0 &&
                          (destinationNames[c].text
                                  .trim()
                                  .toLowerCase()
                                  .startsWith('ficticio') ||
                              destinationIds[c].contains('_dummy_'))) {
                        c--;
                      }
                      if (c >= 0) {
                        destinationFocusNodes[c].requestFocus();
                      }
                    } else if (targetCol == -1 && targetRow >= 0) {
                      var r = targetRow;
                      while (r >= 0 &&
                          (originNames[r].text.trim().toLowerCase().startsWith(
                                'ficticio',
                              ) ||
                              originIds[r].contains('_dummy_'))) {
                        r--;
                      }
                      if (r >= 0) {
                        originFocusNodes[r].requestFocus();
                      }
                    } else if (targetRow >= 0 && targetCol >= 0) {
                      final dr = targetRow > i ? 1 : (targetRow < i ? -1 : 0);
                      final dc = targetCol > j ? 1 : (targetCol < j ? -1 : 0);
                      var r = targetRow;
                      var c = targetCol;
                      while (r >= 0 &&
                          r < originNames.length &&
                          c >= 0 &&
                          c < destinationNames.length) {
                        final isCellDisabled =
                            originNames[r].text.trim().toLowerCase().startsWith(
                              'ficticio',
                            ) ||
                            originIds[r].contains('_dummy_') ||
                            destinationNames[c].text
                                .trim()
                                .toLowerCase()
                                .startsWith('ficticio') ||
                            destinationIds[c].contains('_dummy_');
                        if (!isCellDisabled) {
                          cellFocusNodes[r][c].requestFocus();
                          return;
                        }
                        if (dr == 0 && dc == 0) break;
                        r += dr;
                        c += dc;
                      }
                    }
                  },
                ),
              );
            }),
          ],
        );
      }),
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
