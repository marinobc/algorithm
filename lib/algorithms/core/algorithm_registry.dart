import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../assignment/assignment_algorithm.dart';
import '../assignment/domain/policy/assignment_graph_policy.dart';
import '../assignment/providers/assignment_provider.dart';
import '../johnson/johnson_algorithm.dart';
import '../johnson/providers/johnson_provider.dart';
import '../northwest/northwest_algorithm.dart';
import '../northwest/providers/northwest_provider.dart';
import 'graph_algorithm.dart';

/// Central registry managing all registered graph algorithms.
class AlgorithmRegistry {
  static const String assignmentId = AssignmentAlgorithm.algorithmId;
  static const String johnsonId = JohnsonAlgorithm.algorithmId;
  static const String northwestId = NorthwestAlgorithm.algorithmId;

  static final List<GraphAlgorithm> registeredAlgorithms = [
    const AssignmentAlgorithm(),
    const JohnsonAlgorithm(),
    const NorthwestAlgorithm(),
  ];

  static GraphAlgorithm? findById(String? id) {
    if (id == null) return null;
    try {
      return registeredAlgorithms.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Provider exposing the list of all registered algorithms.
final algorithmRegistryProvider = Provider<List<GraphAlgorithm>>((ref) {
  return AlgorithmRegistry.registeredAlgorithms;
});

/// Notifier managing the currently active algorithm mode in the workspace.
/// When null, the editor is in unrestricted "Modo Libre" (standard freehand graph).
class ActiveAlgorithmNotifier extends Notifier<GraphAlgorithm?> {
  @override
  GraphAlgorithm? build() => null;

  void selectAlgorithm(GraphAlgorithm? algorithm) {
    state = algorithm;
    _syncAlgorithmNotifiers(algorithm?.id);
  }

  void selectById(String? algorithmId) {
    state = AlgorithmRegistry.findById(algorithmId);
    _syncAlgorithmNotifiers(algorithmId);
  }

  void clear() {
    state = null;
    _syncAlgorithmNotifiers(null);
  }

  void _syncAlgorithmNotifiers(String? activeId) {
    // When switching algorithm modes, deactivate any previous execution state
    // so the user starts fresh in the new mode without auto-triggering optimization.
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(false);

    if (activeId == AlgorithmRegistry.assignmentId) {
      ref
          .read(assignmentActiveRoleProvider.notifier)
          .setRole(AssignmentRoles.origin);
    }
  }
}

final activeAlgorithmProvider =
    NotifierProvider<ActiveAlgorithmNotifier, GraphAlgorithm?>(() {
      return ActiveAlgorithmNotifier();
    });

/// Convenience provider returning the active algorithm's policy (or null if free mode).
final activePolicyProvider = Provider<GraphAlgorithmPolicy?>((ref) {
  final activeAlgo = ref.watch(activeAlgorithmProvider);
  if (activeAlgo == null) return null;

  return activeAlgo.policy;
});

/// Convenience provider returning whether a solution calculation card is active for the current algorithm mode.
final isSolutionActiveProvider = Provider<bool>((ref) {
  final activeAlgo = ref.watch(activeAlgorithmProvider);
  if (activeAlgo == null) return false;

  if (activeAlgo.id == AlgorithmRegistry.assignmentId) {
    return ref.watch(transportationNotifierProvider).isActive;
  } else if (activeAlgo.id == AlgorithmRegistry.johnsonId) {
    return ref.watch(johnsonNotifierProvider).isActive;
  } else if (activeAlgo.id == AlgorithmRegistry.northwestId) {
    return ref.watch(northwestNotifierProvider).isActive;
  }
  return false;
});
