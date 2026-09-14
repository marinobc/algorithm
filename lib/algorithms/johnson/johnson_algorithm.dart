import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/nodo.dart';
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
}
