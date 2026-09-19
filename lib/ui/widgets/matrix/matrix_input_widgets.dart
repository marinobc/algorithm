import 'package:flutter/material.dart';

/// Modular, responsive header bar displaying dimensions or add/remove step buttons.
class MatrixDimensionBar extends StatelessWidget {
  final bool hasMatrix;
  final int rowCount;
  final int columnCount;
  final int maxDimension;
  final TextEditingController rowsInputController;
  final TextEditingController colsInputController;
  final VoidCallback onAddRow;
  final VoidCallback onRemoveRow;
  final VoidCallback onAddColumn;
  final VoidCallback onRemoveColumn;
  final VoidCallback onApplyDimensions;

  const MatrixDimensionBar({
    super.key,
    required this.hasMatrix,
    required this.rowCount,
    required this.columnCount,
    this.maxDimension = 12,
    required this.rowsInputController,
    required this.colsInputController,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onAddColumn,
    required this.onRemoveColumn,
    required this.onApplyDimensions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: hasMatrix
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grid_on_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Filas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$rowCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Quitar fila al final',
                          onPressed: onRemoveRow,
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Agregar fila al final',
                          onPressed: onAddRow,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 18,
                          width: 1,
                          margin: const EdgeInsets.only(right: 16),
                          color: colors.outlineVariant,
                        ),
                        const Text(
                          'Cols:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$columnCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Quitar columna al final',
                          onPressed: onRemoveColumn,
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Agregar columna al final',
                          onPressed: onAddColumn,
                        ),
                      ],
                    ),
                  ],
                )
              : Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grid_on_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dimensiones:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 55,
                          child: TextField(
                            controller: rowsInputController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Filas',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onTap: () {
                              if (rowsInputController.text.isNotEmpty) {
                                rowsInputController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: rowsInputController.text.length,
                                );
                              }
                            },
                            onSubmitted: (_) => onApplyDimensions(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '×',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 55,
                          child: TextField(
                            controller: colsInputController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Cols',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onTap: () {
                              if (colsInputController.text.isNotEmpty) {
                                colsInputController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: colsInputController.text.length,
                                );
                              }
                            },
                            onSubmitted: (_) => onApplyDimensions(),
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onApplyDimensions,
                      icon: const Icon(Icons.table_chart_rounded, size: 16),
                      label: const Text(
                        'Crear Matriz',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Modular cell input widget with real-time "AJAX-style" validation, subtle disappearing hints,
/// full-selection on tap, and red warning styles for invalid or negative numbers.
class MatrixCellInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isHighlight;
  final bool readOnly;
  final double width;

  const MatrixCellInput({
    super.key,
    required this.controller,
    this.hint = '',
    this.isHighlight = false,
    this.readOnly = false,
    this.width = 76,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final raw = value.text.trim();
            final parsed = double.tryParse(raw);
            final isInvalid =
                !readOnly &&
                raw.isNotEmpty &&
                (parsed == null || !parsed.isFinite || parsed < 0);

            final hasFocus = Focus.of(context).hasFocus;
            return TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight || isInvalid
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: isInvalid
                    ? colors.error
                    : (readOnly
                          ? colors.onSurfaceVariant.withValues(alpha: 0.7)
                          : (isHighlight ? colors.primary : colors.onSurface)),
              ),
              decoration: InputDecoration(
                hintText: hasFocus ? '' : hint,
                hintStyle: TextStyle(
                  color: isInvalid
                      ? colors.error.withValues(alpha: 0.5)
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isInvalid
                        ? colors.error
                        : colors.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isInvalid
                        ? colors.error
                        : (readOnly
                              ? colors.outlineVariant.withValues(alpha: 0.2)
                              : (isHighlight
                                    ? colors.primary.withValues(alpha: 0.5)
                                    : colors.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ))),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isInvalid
                        ? colors.error
                        : (readOnly ? colors.outlineVariant : colors.primary),
                    width: isInvalid || !readOnly ? 2 : 1,
                  ),
                ),
                fillColor: isInvalid
                    ? colors.errorContainer.withValues(alpha: 0.25)
                    : (readOnly
                          ? colors.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            )
                          : (isHighlight
                                ? colors.primaryContainer.withValues(alpha: 0.3)
                                : colors.surface)),
                filled: true,
              ),
              onTap: () {
                if (!readOnly && controller.text.isNotEmpty) {
                  controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller.text.length,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
