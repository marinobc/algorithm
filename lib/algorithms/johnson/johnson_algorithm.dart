import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../../ui/dialogs/connection_value_input_dialog.dart';
import '../core/graph_algorithm.dart';
import 'domain/policy/johnson_graph_policy.dart';
import 'providers/johnson_provider.dart';

import 'ui/johnson_algorithm_card.dart';
import 'ui/johnson_canvas_controls.dart';
import 'ui/johnson_launch_button.dart';

/// Pluggable GraphAlgorithm implementation for Johnson / CPM (Critical Path Method).
class JohnsonAlgorithm implements GraphAlgorithm {
  static const String algorithmId = 'johnson';

  const JohnsonAlgorithm();

  @override
  String get id => algorithmId;

  @override
  String get name => 'Algoritmo de Johnson / CPM';

  @override
  String get shortName => 'Johnson';

  @override
  String get description =>
      'Ruta Crítica (CPM) y holguras sobre redes de actividades dirigidas acíclicas (DAG).';

  @override
  IconData get icon => Icons.alt_route_rounded;

  @override
  Color get themeColor => const Color(0xFF00BFA5);

  @override
  GraphAlgorithmPolicy get policy => const JohnsonGraphPolicy();

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) {
    return const JohnsonLaunchButton();
  }

  @override
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) {
    return const JohnsonCanvasControls();
  }

  @override
  Map<String, dynamic>? newNodeParams(WidgetRef ref) => null;

  @override
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) => null;

  @override
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(johnsonValidationProvider);
    final state = ref.watch(johnsonNotifierProvider);

    if (state.isActive && validation.isValid) {
      return const JohnsonAlgorithmCard();
    }
    return null;
  }

  @override
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) => null;

  @override
  bool get supportsMatrix => false;

  @override
  String? get matrixUnavailableReason =>
      'El algoritmo de Johnson / CPM opera sobre redes de actividades acíclicas (DAG) y listas de predecesores; no utiliza matriz de adyacencia.';

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) => null;

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
      title: 'Duración de Actividad (Johnson)',
      valueLabel: 'Duración de Actividad',
    );
  }

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    // Opens the single-connection value input popup (pre-filled with default),
    // allowing the user to set the duration immediately after creating the connection.
    showConnectionValueInputDialog(context, ref, conexion);
    return Future.value();
  }

  @override
  Future<void> onNodeCreated(BuildContext context, WidgetRef ref, Nodo nodo) =>
      Future.value();
}
