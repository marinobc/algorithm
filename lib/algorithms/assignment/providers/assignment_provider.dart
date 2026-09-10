import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/highlights/algorithm_highlight.dart';
import '../../johnson/providers/johnson_provider.dart';
import '../domain/models/assignment_models.dart';
import '../domain/services/assignment_matrix_extractor.dart';
import '../domain/services/assignment_validator.dart';
import '../domain/solvers/hungarian_solver.dart';

/// Provider for checking if the current graph qualifies for Transportation / Assignation
final transportationValidationProvider =
    Provider<TransportationValidationResult>((ref) {
      final grafo = ref.watch(grafoProvider);
      return TransportationValidator.validate(grafo);
    });

class TransportationState {
  final bool isActive;
  final bool isAssignmentMode;
  final TransportationMethod selectedMethod;
  final OptimizationGoal optimizationGoal;
  final Map<String, double> customSupplies;
  final Map<String, double> customDemands;

  const TransportationState({
    this.isActive = false,
    this.isAssignmentMode = true,
    this.selectedMethod = TransportationMethod.hungarian,
    this.optimizationGoal = OptimizationGoal.minimize,
    this.customSupplies = const {},
    this.customDemands = const {},
  });

  TransportationState copyWith({
    bool? isActive,
    bool? isAssignmentMode,
    TransportationMethod? selectedMethod,
    OptimizationGoal? optimizationGoal,
    Map<String, double>? customSupplies,
    Map<String, double>? customDemands,
  }) {
    return TransportationState(
      isActive: isActive ?? this.isActive,
      isAssignmentMode: isAssignmentMode ?? this.isAssignmentMode,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      optimizationGoal: optimizationGoal ?? this.optimizationGoal,
      customSupplies: customSupplies ?? this.customSupplies,
      customDemands: customDemands ?? this.customDemands,
    );
  }
}

class TransportationNotifier extends Notifier<TransportationState> {
  @override
  TransportationState build() {
    // Automatically turn off algorithm mode if graph structure becomes invalid
    ref.listen<TransportationValidationResult>(
      transportationValidationProvider,
      (previous, next) {
        if (!next.isValid && state.isActive) {
          state = state.copyWith(isActive: false);
        }
      },
    );
    return const TransportationState();
  }

  void toggleActive() {
    state = state.copyWith(isActive: !state.isActive);
  }

  void setActive(bool active) {
    state = state.copyWith(isActive: active);
  }

  void setMode({required bool isAssignment}) {
    state = state.copyWith(isAssignmentMode: isAssignment);
  }

  void setMethod(TransportationMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  void setGoal(OptimizationGoal goal) {
    state = state.copyWith(optimizationGoal: goal);
  }

  void updateSupply(String originId, double value) {
    final updated = Map<String, double>.from(state.customSupplies);
    updated[originId] = value;
    state = state.copyWith(customSupplies: updated);
  }

  void updateDemand(String destinationId, double value) {
    final updated = Map<String, double>.from(state.customDemands);
    updated[destinationId] = value;
    state = state.copyWith(customDemands: updated);
  }

  void resetCustomQuantities() {
    state = state.copyWith(customSupplies: {}, customDemands: {});
  }
}

final transportationNotifierProvider =
    NotifierProvider<TransportationNotifier, TransportationState>(() {
      return TransportationNotifier();
    });

/// Computed provider returning problem extracted matrix data
final transportationProblemDataProvider = Provider<TransportationProblemData?>((
  ref,
) {
  final validation = ref.watch(transportationValidationProvider);
  if (!validation.isValid) return null;

  final grafo = ref.watch(grafoProvider);
  final state = ref.watch(transportationNotifierProvider);

  return AssignmentMatrixExtractor.extract(
    grafo,
    validation,
    customSupplies: state.customSupplies.isNotEmpty
        ? state.customSupplies
        : null,
    customDemands: state.customDemands.isNotEmpty ? state.customDemands : null,
  );
});

/// Computed provider calculating Transportation algorithm result
final transportationResultProvider = Provider<TransportationResult?>((ref) {
  final problem = ref.watch(transportationProblemDataProvider);
  if (problem == null) return null;

  final state = ref.watch(transportationNotifierProvider);
  final solver = HungarianAssignmentSolver();

  return solver.solve(
    problem: problem,
    method: state.selectedMethod,
    goal: state.optimizationGoal,
  );
});

/// Provider that computes active modular [AlgorithmHighlight] for canvas visualization
final algorithmHighlightProvider = Provider<AlgorithmHighlight>((ref) {
  final state = ref.watch(transportationNotifierProvider);
  if (!state.isActive) {
    return const AlgorithmHighlight();
  }

  final result = ref.watch(transportationResultProvider);
  final problem = ref.watch(transportationProblemDataProvider);
  final grafo = ref.watch(grafoProvider);

  if (result == null || problem == null) {
    return const AlgorithmHighlight();
  }

  final nodeIds = <String>{};
  final connIds = <String>{};

  for (int i = 0; i < result.allocationMatrix.length; i++) {
    for (int j = 0; j < result.allocationMatrix[i].length; j++) {
      final alloc = result.allocationMatrix[i][j];
      if (alloc > 0) {
        // Only highlight real origin -> real destination assignments.
        // Exclude dummy (ficticio) origin/destination assignments.
        final isRealOrigin = i < problem.origins.length;
        final isRealDestination = j < problem.destinations.length;

        if (isRealOrigin && isRealDestination) {
          final origId = problem.origins[i].id;
          final destId = problem.destinations[j].id;

          nodeIds.add(origId);
          nodeIds.add(destId);

          // Find matching connection in graph
          for (final conn in grafo.conexiones.values) {
            if (conn.nodoOrigenId == origId && conn.nodoDestinoId == destId) {
              connIds.add(conn.id);
            }
          }
        }
      }
    }
  }

  return AlgorithmHighlight(
    algorithmName: result.method.displayName,
    nodeIds: nodeIds,
    connectionIds: connIds,
  );
});

/// Combined provider for active algorithm highlights across all graph algorithms
final highlightedElementsProvider = Provider<AlgorithmHighlight>((ref) {
  final assignmentHighlight = ref.watch(algorithmHighlightProvider);
  if (assignmentHighlight.isNotEmpty) {
    return assignmentHighlight;
  }
  final johnsonHighlight = ref.watch(johnsonHighlightProvider);
  if (johnsonHighlight.isNotEmpty) {
    return johnsonHighlight;
  }
  return const AlgorithmHighlight();
});
