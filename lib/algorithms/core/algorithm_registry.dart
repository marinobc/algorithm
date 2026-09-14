import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../assignment/assignment_algorithm.dart';
import '../assignment/domain/policy/assignment_graph_policy.dart';
import '../assignment/providers/assignment_provider.dart';
import '../johnson/johnson_algorithm.dart';
import '../johnson/providers/johnson_provider.dart';
import 'graph_algorithm.dart';

/// Central registry managing all registered graph algorithms.
class AlgorithmRegistry {
  static const String assignmentId = AssignmentAlgorithm.algorithmId;
  static const String johnsonId = JohnsonAlgorithm.algorithmId;

  static final List<GraphAlgorithm> registeredAlgorithms = [
    const AssignmentAlgorithm(),
    const JohnsonAlgorithm(),
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
    // If Assignment is chosen, activate its notifier and reset active role
    if (activeId == AlgorithmRegistry.assignmentId) {
      ref.read(transportationNotifierProvider.notifier).setActive(true);
      ref.read(johnsonNotifierProvider.notifier).setActive(false);
      ref
          .read(assignmentActiveRoleProvider.notifier)
          .setRole(AssignmentRoles.origin);
    } else if (activeId == AlgorithmRegistry.johnsonId) {
      ref.read(johnsonNotifierProvider.notifier).setActive(true);
      ref.read(transportationNotifierProvider.notifier).setActive(false);
    } else {
      ref.read(transportationNotifierProvider.notifier).setActive(false);
      ref.read(johnsonNotifierProvider.notifier).setActive(false);
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
