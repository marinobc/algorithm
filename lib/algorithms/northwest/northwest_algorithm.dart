import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/config_provider.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/modo_tipo_nodo.dart';
import '../../domain/models/nodo.dart';
import '../../ui/dialogs/connection_value_input_dialog.dart';
import '../../ui/screens/graph_editor_screen.dart';
import '../core/algorithm_registry.dart';
import '../core/graph_algorithm.dart';
import 'domain/policy/northwest_graph_policy.dart';
import 'providers/northwest_provider.dart';
import 'ui/northwest_algorithm_widgets.dart';
import 'ui/northwest_matrix_screen.dart';
import 'ui/northwest_node_input_dialog.dart';

class NorthwestAlgorithm implements GraphAlgorithm {
  static const String algorithmId = 'northwest';

  const NorthwestAlgorithm();

  @override
  String get id => algorithmId;

  @override
  String get name => 'Northwest';

  @override
  String get shortName => 'Northwest';

  @override
  String get description =>
      'Resuelve problemas de transporte mediante esquina noroeste y optimizacion MODI.';

  @override
  IconData get icon => Icons.grid_view_rounded;

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
  Map<String, dynamic>? newNodeParams(WidgetRef ref) {
    final modo = ref.read(configProvider).modoTipoNodo;
    if (modo == ModoTipoNodo.detectado) {
      return null;
    }
    return {'role': ref.read(northwestActiveRoleProvider)};
  }

  @override
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) => null;

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
    return ConnectionValueInputDialog.show(
      context: context,
      ref: ref,
      conexion: conexion,
      title: 'Costo de Transporte (Esquina Noroeste)',
      valueLabel: 'Costo unitario de transporte (no negativo)',
    );
  }

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) async {
    final result = await showConnectionValueInputDialog(context, ref, conexion);
    if (result == true) {
      ref.read(northwestNotifierProvider.notifier).setActive(false);
    }
  }

  @override
  Future<void> onNodeCreated(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) async {
    final result = await NorthwestNodeInputDialog.show(context, ref, nodo);
    if (result == true) {
      ref.read(northwestNotifierProvider.notifier).setActive(false);
    }
  }
}
