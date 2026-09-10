import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/highlights/algorithm_highlight.dart';
import '../domain/models/johnson_models.dart';
import '../domain/services/johnson_validator.dart';
import '../domain/solvers/johnson_solver.dart';

final johnsonValidationProvider = Provider<JohnsonValidationResult>((ref) {
  final grafo = ref.watch(grafoProvider);
  return JohnsonValidator.validate(grafo);
});

class JohnsonState {
  final bool isActive;

  const JohnsonState({this.isActive = false});

  JohnsonState copyWith({bool? isActive}) {
    return JohnsonState(isActive: isActive ?? this.isActive);
  }
}

class JohnsonNotifier extends Notifier<JohnsonState> {
  @override
  JohnsonState build() {
    ref.listen<JohnsonValidationResult>(johnsonValidationProvider, (
      previous,
      next,
    ) {
      if (!next.isValid && state.isActive) {
        state = state.copyWith(isActive: false);
      }
    });
    return const JohnsonState();
  }

  void toggleActive() {
    state = state.copyWith(isActive: !state.isActive);
  }

  void setActive(bool active) {
    state = state.copyWith(isActive: active);
  }
}

final johnsonNotifierProvider = NotifierProvider<JohnsonNotifier, JohnsonState>(
  () {
    return JohnsonNotifier();
  },
);

final johnsonResultProvider = Provider<JohnsonResult?>((ref) {
  final validation = ref.watch(johnsonValidationProvider);
  if (!validation.isValid) return null;

  final state = ref.watch(johnsonNotifierProvider);
  if (!state.isActive) return null;

  final grafo = ref.watch(grafoProvider);
  final solver = JohnsonSolver();
  return solver.solve(grafo);
});

final johnsonHighlightProvider = Provider<AlgorithmHighlight>((ref) {
  final state = ref.watch(johnsonNotifierProvider);
  if (!state.isActive) {
    return const AlgorithmHighlight();
  }

  final result = ref.watch(johnsonResultProvider);
  if (result == null) {
    return const AlgorithmHighlight();
  }

  return AlgorithmHighlight(
    algorithmName: 'Algoritmo de Johnson',
    nodeIds: result.criticalNodeIds,
    connectionIds: result.criticalConnectionIds,
  );
});
