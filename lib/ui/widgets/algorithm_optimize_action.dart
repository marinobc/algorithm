import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/domain/models/assignment_models.dart';
import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/graph_paths/providers/graph_path_run_provider.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../algorithms/northwest/domain/models/northwest_models.dart';
import '../../algorithms/northwest/domain/services/northwest_problem_extractor.dart';
import '../../algorithms/northwest/providers/northwest_provider.dart';
import '../../application/providers/grafo_provider.dart';
import 'app_toast.dart';

Future<bool> runActiveAlgorithm(BuildContext context, WidgetRef ref) async {
  final activeAlgo = ref.read(activeAlgorithmProvider);
  if (activeAlgo == null) {
    AppToast.show(
      context,
      'Selecciona un algoritmo antes de optimizar.',
      icon: Icons.info_outline_rounded,
    );
    return false;
  }

  if (activeAlgo.id == AlgorithmRegistry.dijkstraId ||
      activeAlgo.id == AlgorithmRegistry.kruskalId) {
    final graph = ref.read(grafoProvider);
    if (graph.nodos.isEmpty) {
      AppToast.show(
        context,
        'Crea al menos un vértice en el lienzo para calcular.',
        icon: Icons.info_outline_rounded,
      );
      return false;
    }
    ref.read(graphPathRunProvider.notifier).run(graph);
    final run = ref.read(graphPathRunProvider);
    if (run.error != null) {
      AppToast.show(
        context,
        run.error!,
        icon: Icons.warning_amber_rounded,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
    AppToast.show(
      context,
      run.computation?.summary ?? 'Cálculo completado.',
      icon: Icons.check_circle_rounded,
      duration: const Duration(seconds: 3),
    );
    return true;
  }

  if (activeAlgo.id == AlgorithmRegistry.assignmentId) {
    final validation = ref.read(transportationValidationProvider);
    if (!validation.isValid) {
      AppToast.show(
        context,
        validation.errorMessage ?? 'Grafo no válido para Asignación.',
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }
    final goal = await showDialog<OptimizationGoal>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Objetivo de optimización'),
        content: const Text('Selecciona cómo evaluar la asignación.'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, OptimizationGoal.minimize),
            icon: const Icon(Icons.trending_down_rounded),
            label: const Text('Minimizar costo'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, OptimizationGoal.maximize),
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text('Maximizar beneficio'),
          ),
        ],
      ),
    );
    if (goal == null || !context.mounted) return false;

    ref.read(transportationNotifierProvider.notifier).setGoal(goal);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    ref.read(transportationNotifierProvider.notifier).setActive(true);
    AppToast.show(
      context,
      'Optimizando con Algoritmo de Asignación...',
      icon: Icons.play_arrow_rounded,
      duration: const Duration(seconds: 2),
    );
    return true;
  }

  if (activeAlgo.id == AlgorithmRegistry.johnsonId) {
    final validation = ref.read(johnsonValidationProvider);
    if (!validation.isValid) {
      AppToast.show(
        context,
        validation.errorMessage ?? 'Grafo no válido para Johnson.',
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(true);
    AppToast.show(
      context,
      'Optimizando con Johnson...',
      icon: Icons.play_arrow_rounded,
      duration: const Duration(seconds: 2),
    );
    return true;
  }

  if (activeAlgo.id == AlgorithmRegistry.northwestId) {
    final validation = ref.read(northwestValidationProvider);
    if (!validation.isValid) {
      AppToast.show(
        context,
        validation.errorMessage ?? 'Configura una matriz de transporte válida.',
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }
    final objective = await showDialog<TransportationObjective>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Objetivo de optimización'),
        content: const Text('Selecciona cómo evaluar la distribución.'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, TransportationObjective.minimize),
            icon: const Icon(Icons.trending_down_rounded),
            label: const Text('Minimizar costo'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, TransportationObjective.maximize),
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text('Maximizar beneficio'),
          ),
        ],
      ),
    );
    if (objective == null || !context.mounted) return false;
    final graph = ref.read(grafoProvider);
    final metadata = Map<String, String>.from(graph.metadata)
      ..[NorthwestMetadata.objective] = objective.name;
    ref
        .read(grafoProvider.notifier)
        .reemplazarGrafo(graph.copyWith(metadata: metadata));
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(true);
    AppToast.show(
      context,
      'Resolviendo con Esquina Noroeste y MODI...',
      icon: Icons.play_arrow_rounded,
      duration: const Duration(seconds: 2),
    );
    return true;
  }

  return false;
}
