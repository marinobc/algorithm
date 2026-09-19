import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/highlights/algorithm_highlight.dart';
import '../domain/models/northwest_models.dart';
import '../domain/services/northwest_problem_extractor.dart';
import '../domain/solvers/northwest_modi_solver.dart';

class NorthwestRoleNotifier extends Notifier<String> {
  @override
  String build() => NorthwestRoles.origin;

  void setRole(String role) => state = role;
}

final northwestActiveRoleProvider =
    NotifierProvider<NorthwestRoleNotifier, String>(NorthwestRoleNotifier.new);

final northwestValidationProvider = Provider<NorthwestValidationResult>((ref) {
  return NorthwestProblemExtractor.extract(ref.watch(grafoProvider));
});

final northwestProblemProvider = Provider<TransportationInput?>((ref) {
  return ref.watch(northwestValidationProvider).problem;
});

class NorthwestState {
  final bool isActive;

  const NorthwestState({this.isActive = false});
}

class NorthwestNotifier extends Notifier<NorthwestState> {
  @override
  NorthwestState build() => const NorthwestState();

  void setActive(bool active) => state = NorthwestState(isActive: active);
}

final northwestNotifierProvider =
    NotifierProvider<NorthwestNotifier, NorthwestState>(NorthwestNotifier.new);

final northwestResultProvider = Provider<NorthwestResult?>((ref) {
  if (!ref.watch(northwestNotifierProvider).isActive) return null;
  final problem = ref.watch(northwestProblemProvider);
  return problem == null ? null : const NorthwestModiSolver().solve(problem);
});

final northwestHighlightProvider = Provider<AlgorithmHighlight>((ref) {
  final result = ref.watch(northwestResultProvider);
  final problem = ref.watch(northwestProblemProvider);
  final graph = ref.watch(grafoProvider);
  if (result == null || problem == null) return const AlgorithmHighlight();

  final nodeIds = <String>{};
  final connectionIds = <String>{};
  for (var i = 0; i < result.allocations.length; i++) {
    for (var j = 0; j < result.allocations[i].length; j++) {
      if (result.allocations[i][j] <= NorthwestModiSolver.tolerance) continue;
      final originId = problem.originIds[i];
      final destinationId = problem.destinationIds[j];
      nodeIds.addAll([originId, destinationId]);
      for (final connection in graph.conexiones.values) {
        if (connection.nodoOrigenId == originId &&
            connection.nodoDestinoId == destinationId) {
          connectionIds.add(connection.id);
        }
      }
    }
  }
  return AlgorithmHighlight(
    algorithmName: 'Esquina Noroeste / MODI',
    nodeIds: nodeIds,
    connectionIds: connectionIds,
  );
});
