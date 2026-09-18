import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_provider.dart';
import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';

/// Modular, elegant dialog for inputting/editing a connection's numeric value (weight/cost/duration).
class ConnectionValueInputDialog extends ConsumerStatefulWidget {
  final Conexion conexion;
  final String title;
  final String? valueLabel;

  const ConnectionValueInputDialog({
    super.key,
    required this.conexion,
    this.title = 'Valor de la Conexión',
    this.valueLabel = 'Valor / Costo',
  });

  static Future<bool?> show({
    required BuildContext context,
    required WidgetRef ref,
    required Conexion conexion,
    String title = 'Valor de la Conexión',
    String? valueLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConnectionValueInputDialog(
        conexion: conexion,
        title: title,
        valueLabel: valueLabel,
      ),
    );
  }

  @override
  ConsumerState<ConnectionValueInputDialog> createState() =>
      _ConnectionValueInputDialogState();
}

class _ConnectionValueInputDialogState
    extends ConsumerState<ConnectionValueInputDialog> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInvalid = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '');
    _focusNode = FocusNode();

    // Select all text when focused
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final parsed = double.tryParse(raw);

    if (raw.isEmpty || parsed == null || parsed < 0) {
      setState(() {
        _isInvalid = true;
      });
      return;
    }

    final cleanValue = (parsed % 1 == 0)
        ? parsed.toInt().toString()
        : parsed.toString();

    final updatedAttrs = [
      AtributoValor(atributoId: 'attr_valor', valor: cleanValue),
    ];

    ref
        .read(grafoProvider.notifier)
        .actualizarConexion(widget.conexion.id, atributos: updatedAttrs);

    setState(() {
      _canPop = true;
    });

    Navigator.of(context).pop(true);
  }

  void _cancel() {
    ref.read(grafoProvider.notifier).eliminarConexion(widget.conexion.id);

    setState(() {
      _canPop = true;
    });

    Navigator.of(context).pop(false);
  }

  void _handleOutsideOrBackDismiss() {
    final raw = _controller.text.trim();
    final parsed = double.tryParse(raw);

    if (raw.isNotEmpty && parsed != null && parsed >= 0) {
      _submit();
    } else {
      _cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grafo = ref.watch(grafoProvider);

    final orig = grafo.nodos[widget.conexion.nodoOrigenId];
    final dest = grafo.nodos[widget.conexion.nodoDestinoId];

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleOutsideOrBackDismiss();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visual Connection Representation (Origin -> Destination)
                if (orig != null && dest != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildNodeChip(context, orig, isOrigin: true),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: _buildNodeChip(context, dest, isOrigin: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Value Input Field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: widget.valueLabel ?? 'Valor / Costo',
                    hintText: 'Introduzca el valor',
                    isDense: true,
                    errorText: _isInvalid
                        ? 'Ingrese un valor numérico válido (>= 0)'
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                  ),
                  onChanged: (_) {
                    if (_isInvalid) {
                      setState(() {
                        _isInvalid = false;
                      });
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _cancel,
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aceptar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeChip(
    BuildContext context,
    Nodo node, {
    required bool isOrigin,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasColor = node.colorValue != 0;
    final nodeColor = hasColor
        ? Color(node.colorValue)
        : (isOrigin
              ? colorScheme.secondaryContainer
              : colorScheme.primaryContainer);

    final textColor = hasColor
        ? (ThemeData.estimateBrightnessForColor(nodeColor) == Brightness.dark
              ? Colors.white
              : Colors.black)
        : (isOrigin
              ? colorScheme.onSecondaryContainer
              : colorScheme.onPrimaryContainer);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        node.nombre ?? node.id,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
