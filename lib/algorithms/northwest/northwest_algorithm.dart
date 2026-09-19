import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_provider.dart';
import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../../ui/screens/graph_editor_screen.dart';
import '../core/algorithm_registry.dart';
import '../core/graph_algorithm.dart';
import 'domain/policy/northwest_graph_policy.dart';
import 'providers/northwest_provider.dart';
import 'ui/northwest_algorithm_widgets.dart';
import 'ui/northwest_matrix_screen.dart';

class NorthwestAlgorithm implements GraphAlgorithm {
  static const String algorithmId = 'northwest';

  const NorthwestAlgorithm();

  @override
  String get id => algorithmId;

  @override
  String get name => 'Algoritmo de Esquina Noroeste';

  @override
  String get shortName => 'Esquina Noroeste';

  @override
  String get description =>
      'Resuelve problemas de transporte mediante esquina noroeste y optimizacion MODI.';

  @override
  IconData get icon => Icons.local_shipping_outlined;

  @override
  Color get themeColor => const Color(0xFFE54872);

  @override
  GraphAlgorithmPolicy get policy => const NorthwestGraphPolicy();

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) {
    return NorthwestLaunchButton(
      onPressed: () {
        ref
            .read(activeAlgorithmProvider.notifier)
            .selectById(AlgorithmRegistry.northwestId);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
        );
      },
    );
  }

  @override
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) =>
      const NorthwestCanvasControls();

  @override
  Map<String, dynamic>? newNodeParams(WidgetRef ref) => {
    'role': ref.read(northwestActiveRoleProvider),
  };

  @override
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) =>
      const NorthwestEmptyState();

  @override
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) {
    return ref.watch(northwestNotifierProvider).isActive
        ? const NorthwestAlgorithmCard()
        : null;
  }

  @override
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) {
    return NorthwestQuantityEditor(node: nodo);
  }

  @override
  bool get supportsMatrix => true;

  @override
  String? get matrixUnavailableReason => null;

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) =>
      const NorthwestMatrixScreen();

  @override
  Future<bool?> showConnectionValueInputDialog(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    final current = conexion.atributos
        .where((attribute) => attribute.atributoId == 'attr_valor')
        .firstOrNull
        ?.valor;
    final controller = TextEditingController(text: current ?? '');
    String? error;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Costo de transporte'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: InputDecoration(labelText: 'Costo', errorText: error),
            onTap: () => controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value == null || !value.isFinite) {
                  setState(() => error = 'Ingresa un numero finito.');
                  return;
                }
                ref
                    .read(grafoProvider.notifier)
                    .actualizarConexion(
                      conexion.id,
                      atributos: [
                        AtributoValor(
                          atributoId: 'attr_valor',
                          valor: _format(value),
                        ),
                      ],
                    );
                ref.read(northwestNotifierProvider.notifier).setActive(false);
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) async {
    await showConnectionValueInputDialog(context, ref, conexion);
  }

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
