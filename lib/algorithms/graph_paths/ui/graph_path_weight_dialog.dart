import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../../../domain/models/atributo.dart';
import '../../../domain/models/conexion.dart';

class GraphPathWeightDialog extends ConsumerStatefulWidget {
  final Conexion connection;
  final bool allowNegative;
  final bool deleteOnCancel;

  const GraphPathWeightDialog({
    super.key,
    required this.connection,
    required this.allowNegative,
    required this.deleteOnCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Conexion connection,
    required bool allowNegative,
    bool deleteOnCancel = false,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => GraphPathWeightDialog(
      connection: connection,
      allowNegative: allowNegative,
      deleteOnCancel: deleteOnCancel,
    ),
  );

  @override
  ConsumerState<GraphPathWeightDialog> createState() =>
      _GraphPathWeightDialogState();
}

class _GraphPathWeightDialogState extends ConsumerState<GraphPathWeightDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _canPop = false;
  bool _closing = false;

  void _close(bool result) {
    if (_closing) return;
    _closing = true;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  void initState() {
    super.initState();
    final current = widget.connection.atributos
        .where((a) => a.atributoId == 'attr_valor')
        .map((a) => a.valor)
        .firstOrNull;
    _controller = TextEditingController(text: current ?? '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _controller.text.trim();
    final value = double.tryParse(raw);
    if (raw.isEmpty ||
        value == null ||
        !value.isFinite ||
        (!widget.allowNegative && value < 0)) {
      setState(
        () => _error = widget.allowNegative
            ? 'Introduce un número finito; se admiten negativos y cero.'
            : 'Introduce un número finito mayor o igual que cero.',
      );
      return;
    }
    final attributes =
        widget.connection.atributos
            .where((a) => a.atributoId != 'attr_valor')
            .toList()
          ..insert(0, AtributoValor(atributoId: 'attr_valor', valor: raw));
    ref
        .read(grafoProvider.notifier)
        .actualizarConexion(
          widget.connection.id,
          atributos: attributes,
          recordUndo: true,
        );
    _close(true);
  }

  void _cancel() {
    if (widget.deleteOnCancel) {
      ref.read(grafoProvider.notifier).eliminarConexion(widget.connection.id);
    }
    _close(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: AlertDialog(
        title: const Text('Peso de la arista'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El peso se usará en todos los cálculos y se mostrará sobre la arista.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: 'Peso',
                  helperText: widget.allowNegative
                      ? 'Admite negativos, cero y decimales.'
                      : 'Admite cero y decimales.',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _cancel, child: const Text('Cancelar')),
          FilledButton(onPressed: _save, child: const Text('Confirmar peso')),
        ],
      ),
    );
  }
}
