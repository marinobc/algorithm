import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/northwest/providers/northwest_provider.dart';
import '../../application/providers/atributos_provider.dart';
import '../../application/providers/creacion_provider.dart';
import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../widgets/app_toast.dart';

class GraphCanvasDialogs {
  static Future<void> showDeleteNodeDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Nodo nodo,
    required VoidCallback onDeleted,
  }) async {
    final grafo = ref.read(grafoProvider);
    final deletion = ref
        .read(activePolicyProvider)
        ?.canDeleteNode(grafo, nodo.id);
    if (deletion != null && !deletion.allowed) {
      AppToast.show(
        context,
        deletion.message ?? 'No puedes eliminar este nodo.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }
    final conexiones = grafo.obtenerConexionesDeNodo(nodo.id);
    final atributos = ref.read(atributosGlobalesProvider);

    final Map<String, String> attrNames = {
      for (final a in atributos) a.id: a.nombre,
    };
    final Map<String, String> nodeNames = {
      for (final n in grafo.nodos.values) n.id: n.nombre ?? n.id,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return DeleteConfirmationDialog(
          isNode: true,
          nodeName: nodo.nombre ?? nodo.id,
          connectionsToDelete: conexiones,
          attributeNames: attrNames,
          nodeNames: nodeNames,
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    onDeleted();

    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    ref.read(estadoCreacionProvider.notifier).reset();
    ref.read(grafoProvider.notifier).eliminarNodo(nodo.id);
  }

  static Future<void> showDeleteConnectionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Conexion conexion,
    required VoidCallback onDeleted,
  }) async {
    final atributos = ref.read(atributosGlobalesProvider);
    final grafo = ref.read(grafoProvider);
    final deletion = ref
        .read(activePolicyProvider)
        ?.canDeleteConnection(grafo, conexion.id);
    if (deletion != null && !deletion.allowed) {
      AppToast.show(
        context,
        deletion.message ?? 'No puedes eliminar esta conexion.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    final Map<String, String> attrNames = {
      for (final a in atributos) a.id: a.nombre,
    };
    final Map<String, String> nodeNames = {
      for (final n in grafo.nodos.values) n.id: n.nombre ?? n.id,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return DeleteConfirmationDialog(
          isNode: false,
          targetConnection: conexion,
          attributeNames: attrNames,
          nodeNames: nodeNames,
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    onDeleted();

    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    ref.read(grafoProvider.notifier).eliminarConexion(conexion.id);
  }

  static Future<void> showQuantityEditor({
    required BuildContext context,
    required WidgetRef ref,
    required Nodo node,
  }) async {
    final controller = TextEditingController(
      text: _formatQuantity(node.cantidad ?? 0),
    );
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            node.rol == 'northwest_origin'
                ? 'Editar oferta / disponibilidad'
                : 'Editar demanda',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: node.rol == 'northwest_origin'
                  ? 'Oferta / disponibilidad'
                  : 'Demanda',
              errorText: error,
            ),
            onTap: () => controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            ),
            onSubmitted: (_) => _saveQuantity(
              dialogContext,
              ref,
              controller,
              node,
              setDialogState,
              (message) => error = message,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => _saveQuantity(
                dialogContext,
                ref,
                controller,
                node,
                setDialogState,
                (message) => error = message,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  static void _saveQuantity(
    BuildContext dialogContext,
    WidgetRef ref,
    TextEditingController controller,
    Nodo node,
    void Function(void Function()) setDialogState,
    void Function(String?) setError,
  ) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || !value.isFinite || value < 0) {
      setDialogState(() => setError('Ingresa un numero no negativo.'));
      return;
    }
    ref.read(grafoProvider.notifier).actualizarNodo(node.id, cantidad: value);
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    Navigator.pop(dialogContext);
  }

  static String _formatQuantity(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
}
