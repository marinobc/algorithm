import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/atributos_provider.dart';
import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../dialogs/connection_duplicate_dialog.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../text/app_text.dart';
import '../text/connection_text.dart';
import '../text/dialog_text.dart';
import '../theme/app_theme.dart';
import 'edit_panel/connection_edit_section.dart';
import 'edit_panel/custom_attributes_section.dart';
import 'edit_panel/node_edit_section.dart';

class EditPanel extends ConsumerStatefulWidget {
  const EditPanel({super.key});

  @override
  ConsumerState<EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends ConsumerState<EditPanel> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _newAttrController = TextEditingController();
  final Map<String, TextEditingController> _attrValueControllers = {};
  final Map<String, TextEditingController> _attrTagNameControllers = {};

  String? _lastSyncedItemId;
  int _selectedColor = 0xFF7C4DFF;
  Direccion _selectedDireccion = Direccion.ninguna;
  String? _selectedOrigenId;
  String? _selectedDestinoId;

  @override
  void dispose() {
    _nameController.dispose();
    _newAttrController.dispose();
    for (final c in _attrValueControllers.values) {
      c.dispose();
    }
    for (final c in _attrTagNameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getAttrController(String attrId) {
    if (!_attrValueControllers.containsKey(attrId)) {
      _attrValueControllers[attrId] = TextEditingController();
    }
    return _attrValueControllers[attrId]!;
  }

  TextEditingController _getAttrTagNameController(
    String attrId,
    String currentName,
  ) {
    if (!_attrTagNameControllers.containsKey(attrId)) {
      _attrTagNameControllers[attrId] = TextEditingController(
        text: currentName,
      );
    } else if (_attrTagNameControllers[attrId]!.text != currentName &&
        !FocusScope.of(context).hasFocus) {
      _attrTagNameControllers[attrId]!.text = currentName;
    }
    return _attrTagNameControllers[attrId]!;
  }

  void _syncWithCurrentItem() {
    final edicion = ref.read(estadoEdicionProvider);
    final grafo = ref.read(grafoProvider);
    final atributos = ref.read(atributosGlobalesProvider);

    if (edicion.itemSeleccionadoId == null) return;

    for (final attr in atributos) {
      if (!_attrTagNameControllers.containsKey(attr.id)) {
        _attrTagNameControllers[attr.id] = TextEditingController(
          text: attr.nombre,
        );
      }
    }

    if (edicion.esNodo) {
      final nodo = grafo.nodos[edicion.itemSeleccionadoId];
      if (nodo != null) {
        _nameController.text = nodo.nombre ?? '';
        _selectedColor = nodo.colorValue;
      }
    } else {
      final conn = grafo.conexiones[edicion.itemSeleccionadoId];
      if (conn != null) {
        _selectedColor = conn.colorValue;
        _selectedOrigenId = conn.nodoOrigenId;
        _selectedDestinoId = conn.nodoDestinoId;
        _selectedDireccion = conn.direccion;

        _attrValueControllers.clear();
        for (final av in conn.atributos) {
          _attrValueControllers[av.atributoId] = TextEditingController(
            text: av.valor,
          );
        }
      }
    }
  }

  void _confirmDeleteAttribute(
    BuildContext context,
    Atributo attr,
    NeumorphicPalette palette,
  ) {
    final grafo = ref.read(grafoProvider);
    final affectedValues = <String>[];
    for (final conn in grafo.conexiones.values) {
      for (final av in conn.atributos) {
        if (av.atributoId == attr.id && av.valor.trim().isNotEmpty) {
          affectedValues.add(av.valor.trim());
        }
      }
    }

    final valuesSummary = affectedValues.isEmpty
        ? '(Ningún valor asignado)'
        : affectedValues.join(', ');

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surfaceBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: palette.darkShadow.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: NeumorphicShadows.dialog(palette),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Eliminar atributo "${attr.nombre}"?',
                style: TextStyle(
                  color: palette.alertColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Estas borrando los siguientes valores seguro:',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.canvasBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  valuesSummary,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      AppText.cancel,
                      style: TextStyle(color: palette.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref
                          .read(atributosGlobalesProvider.notifier)
                          .eliminarAtributo(attr.id);
                      ref
                          .read(grafoProvider.notifier)
                          .eliminarAtributoDeConexiones(attr.id);
                      if (mounted) {
                        setState(() {
                          _attrValueControllers.remove(attr.id)?.dispose();
                          _attrTagNameControllers.remove(attr.id)?.dispose();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.alertColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: NeumorphicShadows.inset(
                          palette,
                          distance: 2,
                          blur: 4,
                        ),
                      ),
                      child: const Text(
                        AppText.delete,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final edicion = ref.watch(estadoEdicionProvider);
    final atributosGlobales = ref.watch(atributosGlobalesProvider);
    final palette = NeumorphicPalette.of(context);

    if (edicion.itemSeleccionadoId == null) {
      _lastSyncedItemId = null;
      return const SizedBox.shrink();
    }

    if (_lastSyncedItemId != edicion.itemSeleccionadoId) {
      _lastSyncedItemId = edicion.itemSeleccionadoId;
      _syncWithCurrentItem();
    }

    final isNode = edicion.esNodo;
    final conn = !isNode && edicion.itemSeleccionadoId != null
        ? ref.watch(grafoProvider).conexiones[edicion.itemSeleccionadoId]
        : null;

    final origNodeId = conn?.nodoOrigenId;
    final destNodeId = conn?.nodoDestinoId;

    final origNode = origNodeId != null
        ? ref.watch(grafoProvider).nodos[origNodeId]
        : null;
    final destNode = destNodeId != null
        ? ref.watch(grafoProvider).nodos[destNodeId]
        : null;

    final nameA = origNode?.nombre ?? 'Nodo A';
    final nameB = destNode?.nombre ?? 'Nodo B';
    final isSelfLoop = origNodeId != null && origNodeId == destNodeId;

    final List<_ChoiceOption<String>> directionOptions = [];

    if (isSelfLoop) {
      directionOptions.add(
        _ChoiceOption<String>(
          id: 'undirected',
          label: 'No dirigida',
          onSelect: () {
            setState(() {
              _selectedDireccion = Direccion.ninguna;
            });
          },
        ),
      );
      directionOptions.add(
        _ChoiceOption<String>(
          id: 'directional',
          label: 'Dirigida (Bucle en $nameA)',
          onSelect: () {
            setState(() {
              _selectedDireccion = Direccion.unidireccional;
            });
          },
        ),
      );
    } else {
      directionOptions.add(
        _ChoiceOption<String>(
          id: 'undirected',
          label: 'No dirigida',
          onSelect: () {
            setState(() {
              _selectedDireccion = Direccion.ninguna;
            });
          },
        ),
      );
      directionOptions.add(
        _ChoiceOption<String>(
          id: 'directional',
          label: 'Dirigida ($nameA → $nameB)',
          onSelect: () {
            setState(() {
              _selectedDireccion = Direccion.unidireccional;
              _selectedOrigenId = origNodeId;
              _selectedDestinoId = destNodeId;
            });
          },
        ),
      );
    }

    String currentDirectionOptionId =
        _selectedDireccion == Direccion.unidireccional
        ? 'directional'
        : 'undirected';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final itemTitle = isNode
        ? DialogText.nodeProperties
        : ConnectionText.attributesHeader;

    return Material(
      elevation: 8,
      color: colorScheme.surfaceContainer,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    itemTitle,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(estadoEdicionProvider.notifier).deseleccionar();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Divider(color: colorScheme.outlineVariant),
              if (isNode) ...[
                NodeEditSection(
                  nameController: _nameController,
                  colorScheme: colorScheme,
                  palette: palette,
                  selectedColorValue: _selectedColor,
                  onNameChanged: (_) {
                    ref
                        .read(estadoEdicionProvider.notifier)
                        .marcarCambioSinGuardar();
                  },
                  onColorSelected: (colorVal) {
                    setState(() {
                      _selectedColor = colorVal;
                    });
                    ref
                        .read(estadoEdicionProvider.notifier)
                        .marcarCambioSinGuardar();
                  },
                ),
              ],
              if (!isNode) ...[
                ConnectionEditSection(
                  colorScheme: colorScheme,
                  isSelfLoop: isSelfLoop,
                  selectedDireccion: _selectedDireccion,
                  currentDirectionOptionId: currentDirectionOptionId,
                  directionOptions: directionOptions
                      .map(
                        (opt) => ChoiceChipOption(
                          id: opt.id,
                          label: opt.label,
                          onSelect: opt.onSelect,
                        ),
                      )
                      .toList(),
                  loopAngle: conn?.loopAngle ?? (-3.14159 / 2),
                  onLoopAngleChanged: (val) {
                    if (conn != null) {
                      ref
                          .read(grafoProvider.notifier)
                          .actualizarConexion(conn.id, loopAngle: val);
                      ref
                          .read(estadoEdicionProvider.notifier)
                          .marcarCambioSinGuardar();
                    }
                  },
                ),
              ],
              if (!isNode) ...[
                CustomAttributesSection(
                  atributosGlobales: atributosGlobales,
                  colorScheme: colorScheme,
                  palette: palette,
                  newAttrController: _newAttrController,
                  getAttrController: _getAttrController,
                  getAttrTagNameController: _getAttrTagNameController,
                  onTagRenamed: (attrId, newTag) {
                    ref
                        .read(atributosGlobalesProvider.notifier)
                        .renombrarAtributo(attrId, newTag);
                    ref
                        .read(estadoEdicionProvider.notifier)
                        .marcarCambioSinGuardar();
                  },
                  onValueChanged: () {
                    ref
                        .read(estadoEdicionProvider.notifier)
                        .marcarCambioSinGuardar();
                  },
                  onDeleteAttribute: (attr) {
                    _confirmDeleteAttribute(context, attr, palette);
                  },
                  onAddAttribute: () {
                    final name = _newAttrController.text.trim();
                    if (name.isNotEmpty) {
                      ref
                          .read(atributosGlobalesProvider.notifier)
                          .agregarAtributo(name);
                      _newAttrController.clear();
                    }
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar',
                    onPressed: () => _confirmDeleteItem(context),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          ref
                              .read(estadoEdicionProvider.notifier)
                              .deseleccionar();
                        },
                        child: const Text(AppText.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveChanges,
                        child: const Text(AppText.save),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context) async {
    final edicion = ref.read(estadoEdicionProvider);
    final itemId = edicion.itemSeleccionadoId;
    if (itemId == null) return;

    final grafo = ref.read(grafoProvider);
    final atributos = ref.read(atributosGlobalesProvider);

    final Map<String, String> attrNames = {
      for (final a in atributos) a.id: a.nombre,
    };
    final Map<String, String> nodeNames = {
      for (final n in grafo.nodos.values) n.id: n.nombre ?? n.id,
    };

    if (edicion.esNodo) {
      final nodo = grafo.nodos[itemId];
      if (nodo == null) return;
      final conexiones = grafo.obtenerConexionesDeNodo(nodo.id);

      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (_) => DeleteConfirmationDialog(
          isNode: true,
          nodeName: nodo.nombre ?? nodo.id,
          connectionsToDelete: conexiones,
          attributeNames: attrNames,
          nodeNames: nodeNames,
        ),
      );

      if (confirmed != true) return;
      if (!mounted) return;

      ref.read(grafoProvider.notifier).eliminarNodo(nodo.id);
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
    } else {
      final conn = grafo.conexiones[itemId];
      if (conn == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (_) => DeleteConfirmationDialog(
          isNode: false,
          targetConnection: conn,
          attributeNames: attrNames,
          nodeNames: nodeNames,
        ),
      );

      if (confirmed != true) return;
      if (!mounted) return;

      ref.read(grafoProvider.notifier).eliminarConexion(conn.id);
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
    }
  }

  void _saveChanges() async {
    FocusScope.of(context).unfocus();
    final edicion = ref.read(estadoEdicionProvider);
    final itemId = edicion.itemSeleccionadoId;
    if (itemId == null) return;

    if (edicion.esNodo) {
      ref
          .read(grafoProvider.notifier)
          .actualizarNodo(
            itemId,
            nombre: _nameController.text.trim(),
            colorValue: _selectedColor,
          );
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
    } else {
      final grafo = ref.read(grafoProvider);
      final conn = grafo.conexiones[itemId];
      if (conn == null) return;

      final targetOrigenId = _selectedOrigenId ?? conn.nodoOrigenId;
      final targetDestinoId = _selectedDestinoId ?? conn.nodoDestinoId;

      final existingDuplicate = grafo.conexiones.values.firstWhere(
        (other) =>
            other.id != itemId &&
            other.nodoOrigenId == targetOrigenId &&
            other.nodoDestinoId == targetDestinoId &&
            (other.direccion == _selectedDireccion ||
                _selectedDireccion == Direccion.bidireccional),
        orElse: () => const Conexion(
          id: '',
          nodoOrigenId: '',
          nodoDestinoId: '',
          colorValue: 0,
        ),
      );

      if (existingDuplicate.id.isNotEmpty) {
        final origNode = grafo.nodos[targetOrigenId];
        final destNode = grafo.nodos[targetDestinoId];
        final origName = origNode?.nombre ?? targetOrigenId;
        final destName = destNode?.nombre ?? targetDestinoId;

        final shouldReplace = await ConnectionDuplicateDialog.show(
          context: context,
          origName: origName,
          destName: destName,
        );

        if (shouldReplace != true) {
          return;
        }

        ref.read(grafoProvider.notifier).eliminarConexion(existingDuplicate.id);
      }

      final atributosGlobales = ref.read(atributosGlobalesProvider);
      final attrValues = <AtributoValor>[];

      for (final a in atributosGlobales) {
        String val = _attrValueControllers[a.id]?.text.trim() ?? '';
        if (val.isNotEmpty) {
          final parsed = double.tryParse(val);
          if (parsed == null || parsed <= 0) {
            val = '1';
          }
          attrValues.add(AtributoValor(atributoId: a.id, valor: val));
        }
      }

      ref
          .read(grafoProvider.notifier)
          .actualizarConexion(
            itemId,
            nodoOrigenId: targetOrigenId,
            nodoDestinoId: targetDestinoId,
            colorValue: _selectedColor,
            direccion: _selectedDireccion,
            atributos: attrValues,
          );

      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
    }
  }
}

class _ChoiceOption<T> {
  final T id;
  final String label;
  final VoidCallback onSelect;

  _ChoiceOption({
    required this.id,
    required this.label,
    required this.onSelect,
  });
}

