import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../domain/services/assignment_validator.dart';

class AssignmentMatrixInputDialog extends ConsumerStatefulWidget {
  const AssignmentMatrixInputDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AssignmentMatrixInputDialog(),
    );
  }

  @override
  ConsumerState<AssignmentMatrixInputDialog> createState() =>
      _AssignmentMatrixInputDialogState();
}

class _AssignmentMatrixInputDialogState
    extends ConsumerState<AssignmentMatrixInputDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String> _initialValues = {};
  final Map<String, String> _previousValues = {};
  final Set<String> _invalidKeys = {};
  bool _hasPendingEdits = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _cellKey(String origId, String destId) => '${origId}_$destId';

  void _triggerInvalidFeedback(String key, String fallbackVal) {
    setState(() {
      _invalidKeys.add(key);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _invalidKeys.remove(key);
          _controllers[key]?.text = fallbackVal;
        });
      }
    });
  }

  void _commitCellValue(Nodo orig, Nodo dest, Conexion conn, String rawValue) {
    final val = rawValue.trim();
    final key = _cellKey(orig.id, dest.id);
    final initialVal = _initialValues[key] ?? '';
    final parsed = double.tryParse(val);
    final fallbackVal = _previousValues[key] ?? initialVal;

    if (val.isEmpty ||
        val == '0' ||
        parsed == 0 ||
        parsed == null ||
        parsed < 0) {
      _triggerInvalidFeedback(key, fallbackVal);
      return;
    }

    if (val == initialVal) return;

    final updatedAttrs = [AtributoValor(atributoId: 'attr_valor', valor: val)];
    ref
        .read(grafoProvider.notifier)
        .actualizarConexion(conn.id, atributos: updatedAttrs);
    _initialValues[key] = val;
    _hasPendingEdits = true;
  }

  Future<bool> _handlePopScope() async {
    if (!_hasPendingEdits) return true;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.blue),
            SizedBox(width: 10),
            Text('¿Aplicar valores al grafo?'),
          ],
        ),
        content: const Text(
          'Se han realizado cambios en los valores. ¿Desea aplicar los cambios al grafo o regresar sin cambiar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('Regresar sin cambiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('apply'),
            child: const Text('Aplicar valores'),
          ),
        ],
      ),
    );

    if (choice == 'apply') {
      return true;
    } else if (choice == 'discard') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final grafo = ref.watch(grafoProvider);
    final validation = TransportationValidator.validate(grafo);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final origins = validation.origins.isNotEmpty
        ? validation.origins
        : grafo.nodos.values
              .where((n) => n.rol == 'origen' || n.rol == null)
              .toList();

    final destinations = validation.destinations.isNotEmpty
        ? validation.destinations
        : grafo.nodos.values.where((n) => n.rol == 'destino').toList();

    return PopScope(
      canPop: !_hasPendingEdits,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePopScope();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edición de Valores de Asignación',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Edita los costos de las conexiones existentes en el grafo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () async {
                        if (!_hasPendingEdits) {
                          Navigator.of(context).pop();
                        } else {
                          final shouldPop = await _handlePopScope();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              // Body
              if (origins.isEmpty || destinations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_rows_outlined,
                        size: 48,
                        color: colorScheme.outline.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Agregue nodos de Origen y Destino en el lienzo para habilitar la lista de valores.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: _buildConnectionListView(
                    context,
                    grafo,
                    origins,
                    destinations,
                  ),
                ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: colorScheme.surfaceContainerLow,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (!_hasPendingEdits) {
                          Navigator.of(context).pop();
                        } else {
                          final shouldPop = await _handlePopScope();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aplicar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionListView(
    BuildContext context,
    Grafo grafo,
    List<Nodo> origins,
    List<Nodo> destinations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final existingConnections = <Map<String, dynamic>>[];
    for (final orig in origins) {
      for (final dest in destinations) {
        final conn = grafo.conexiones.values.firstWhere(
          (c) => c.nodoOrigenId == orig.id && c.nodoDestinoId == dest.id,
          orElse: () => const Conexion(
            id: '',
            nodoOrigenId: '',
            nodoDestinoId: '',
            colorValue: 0,
          ),
        );
        if (conn.id.isNotEmpty) {
          existingConnections.add({'orig': orig, 'dest': dest, 'conn': conn});
        }
      }
    }

    if (existingConnections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 48,
              color: colorScheme.outline.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay conexiones dibujadas entre Origen y Destino.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: existingConnections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = existingConnections[index];
        final orig = item['orig'] as Nodo;
        final dest = item['dest'] as Nodo;
        final conn = item['conn'] as Conexion;

        final currentVal = conn.atributos
            .firstWhere(
              (a) => a.atributoId == 'attr_valor',
              orElse: () => const AtributoValor(atributoId: '', valor: '1'),
            )
            .valor;

        final key = _cellKey(orig.id, dest.id);
        _initialValues.putIfAbsent(key, () => currentVal);
        final controller = _controllers.putIfAbsent(
          key,
          () => TextEditingController(text: currentVal),
        );

        final focusNode = _focusNodes.putIfAbsent(key, () {
          final fn = FocusNode();
          fn.addListener(() {
            if (fn.hasFocus) {
              _previousValues[key] = controller.text;
              controller.text = '';
              setState(() {});
            } else {
              if (controller.text.isEmpty && _previousValues[key] != null) {
                controller.text = _previousValues[key]!;
              }
              _commitCellValue(orig, dest, conn, controller.text);
              if (mounted) setState(() {});
            }
          });
          return fn;
        });

        final isFocused = focusNode.hasFocus;
        final isInvalid = _invalidKeys.contains(key);

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isInvalid
                  ? Colors.red
                  : (isFocused
                        ? colorScheme.primary
                        : colorScheme.outlineVariant),
              width: isInvalid || isFocused ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Node Origin Chip
                Expanded(child: _buildNodeChip(context, orig, true)),
                const SizedBox(width: 6),
                // Node Destination Chip
                Expanded(child: _buildNodeChip(context, dest, false)),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                // Value Input Field
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldVal, newVal) {
                        if (newVal.text.isEmpty) return newVal;
                        if (newVal.text == '.') {
                          return const TextEditingValue(text: '0.');
                        }
                        final numVal = double.tryParse(newVal.text);
                        return (numVal != null && numVal >= 0)
                            ? newVal
                            : oldVal;
                      }),
                    ],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: isFocused ? null : '1',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: isInvalid
                          ? Colors.red.withAlpha(30)
                          : colorScheme.surfaceContainerHighest,
                      filled: true,
                    ),
                    onSubmitted: (val) {
                      _commitCellValue(orig, dest, conn, val);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodeChip(BuildContext context, Nodo node, bool isOrigin) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasColor
            ? [
                BoxShadow(
                  color: nodeColor.withAlpha(50),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        node.nombre ?? node.id,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
