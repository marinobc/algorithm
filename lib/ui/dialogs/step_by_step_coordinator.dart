import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../widgets/app_toast.dart';
import 'step_by_step_viewer_dialog.dart';

/// Central coordinator for opening step-by-step mathematical breakdown for the active algorithm.
class StepByStepCoordinator {
  /// Opens the step-by-step math breakdown screen or dialog for the currently active algorithm.
  static void openStepByStep(BuildContext context, WidgetRef ref) {
    final activeAlgo = ref.read(activeAlgorithmProvider);

    // 1. Free Mode: No active algorithm selected
    if (activeAlgo == null) {
      AppToast.show(
        context,
        'Selecciona un algoritmo activo para ver su paso a paso matemático.',
        icon: Icons.alt_route_rounded,
      );
      return;
    }

    // 2. Algorithm does NOT support step-by-step
    if (!activeAlgo.supportsStepByStep) {
      final reason =
          activeAlgo.stepByStepUnavailableReason ??
          'Este algoritmo no tiene un desglose paso a paso configurado.';
      AppToast.show(
        context,
        reason,
        icon: Icons.info_outline_rounded,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // 3. Custom algorithm step screen (if provided)
    final customScreen = activeAlgo.buildStepByStepScreen(context, ref);
    if (customScreen != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => customScreen));
      return;
    }

    // 4. Standard polymorphic StepByStepViewerDialog
    final steps = activeAlgo.getStepByStepList(ref);
    StepByStepViewerDialog.show(context, activeAlgo, steps);
  }
}
