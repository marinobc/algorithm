import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/nodo.dart';
import '../domain/services/northwest_problem_extractor.dart';

/// Modal dialog presented when a node is added in Northwest algorithm mode,
/// allowing the user to set/confirm its name and quantity (Supply / Demand).
class NorthwestNodeInputDialog extends ConsumerStatefulWidget {
  final Nodo node;

  const NorthwestNodeInputDialog({super.key, required this.node});

  static Future<bool?> show(BuildContext context, WidgetRef ref, Nodo node) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NorthwestNodeInputDialog(node: node),
    );
  }

  @override
  ConsumerState<NorthwestNodeInputDialog> createState() =>
      _NorthwestNodeInputDialogState();
}

class _NorthwestNodeInputDialogState
    extends ConsumerState<NorthwestNodeInputDialog> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late FocusNode _nameFocusNode;
  late FocusNode _valueFocusNode;

  bool _isInvalid = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    final initialName = widget.node.nombre ?? '';
    final initialQty = widget.node.cantidad;
    final qtyText = (initialQty != null && initialQty > 0)
        ? (initialQty % 1 == 0
              ? initialQty.toInt().toString()
              : initialQty.toString())
        : '';

    _nameController = TextEditingController(text: initialName);
    _valueController = TextEditingController(text: qtyText);
    _nameFocusNode = FocusNode();
    _valueFocusNode = FocusNode();

    // Select all text in value field when focused
    _valueFocusNode.addListener(() {
      if (_valueFocusNode.hasFocus && _valueController.text.isNotEmpty) {
        _valueController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _valueController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _nameFocusNode.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final rawName = _nameController.text.trim();
    final rawValue = _valueController.text.trim();
    final parsedValue = double.tryParse(rawValue);

    if (rawValue.isNotEmpty && (parsedValue == null || parsedValue < 0)) {
      setState(() {
        _isInvalid = true;
      });
      return;
    }

    final finalName = rawName.isNotEmpty
        ? rawName
        : (widget.node.nombre ?? 'Nodo');
    final finalCantidad = parsedValue ?? widget.node.cantidad ?? 0.0;

    ref
        .read(grafoProvider.notifier)
        .actualizarNodo(
          widget.node.id,
          nombre: finalName,
          cantidad: finalCantidad,
        );

    setState(() {
      _canPop = true;
    });

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOrigin = widget.node.rol == NorthwestRoles.origin;
    final roleTitle = isOrigin ? 'Nuevo Origen' : 'Nuevo Destino';
    final valueLabel = isOrigin
        ? 'Oferta disponible (Capacidad)'
        : 'Demanda requerida';
    final roleIcon = isOrigin ? Icons.upload_rounded : Icons.download_rounded;
    final accentColor = isOrigin ? colorScheme.primary : colorScheme.secondary;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _submit();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        elevation: 6,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(roleIcon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOrigin
                              ? 'Define la oferta y nombre'
                              : 'Define la demanda y nombre',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Name Field (Pre-filled with random / default name)
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nombre del Nodo',
                  hintText: isOrigin ? 'Ej. Origen A' : 'Ej. Destino 1',
                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  _valueFocusNode.requestFocus();
                },
              ),

              const SizedBox(height: 14),

              // Value Field (Focused by default for fast weight entry)
              TextField(
                controller: _valueController,
                focusNode: _valueFocusNode,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: valueLabel,
                  hintText: 'Ingresa un valor numérico',
                  prefixIcon: Icon(
                    isOrigin
                        ? Icons.add_chart_rounded
                        : Icons.pie_chart_outline_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                  errorText: _isInvalid
                      ? 'Ingresa un número válido mayor o igual a 0'
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: _isInvalid
                        ? BorderSide(color: colorScheme.error)
                        : BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _canPop = true;
                      });
                      Navigator.of(context).pop(false);
                    },
                    child: Text(
                      'Omitir',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
