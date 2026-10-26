import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../../../domain/highlights/algorithm_highlight.dart';
import '../../../domain/models/grafo.dart';
import '../domain/graph_path_endpoints.dart';
import '../domain/graph_path_solver.dart';

enum GraphPathMode { dijkstra, longestSimple, kruskalMinimum, kruskalMaximum }

class GraphPathRunState {
  final String? sourceId;
  final String? targetId;
  final bool sourceIsManual;
  final bool targetIsManual;
  final bool inferredFromTopology;
  final GraphPathMode mode;
  final GraphComputation? computation;
  final int stepIndex;
  final int alternativeIndex;
  final String? error;

  const GraphPathRunState({
    this.sourceId,
    this.targetId,
    this.sourceIsManual = false,
    this.targetIsManual = false,
    this.inferredFromTopology = false,
    this.mode = GraphPathMode.dijkstra,
    this.computation,
    this.stepIndex = 0,
    this.alternativeIndex = -1,
    this.error,
  });

  GraphAlgorithmStep? get currentStep {
    final steps = computation?.steps;
    if (steps == null || steps.isEmpty) return null;
    return steps[stepIndex.clamp(0, steps.length - 1)];
  }

  GraphPathRunState copyWith({
    String? sourceId,
    String? targetId,
    bool? sourceIsManual,
    bool? targetIsManual,
    bool? inferredFromTopology,
    GraphPathMode? mode,
    GraphComputation? computation,
    int? stepIndex,
    int? alternativeIndex,
    String? error,
    bool clearSource = false,
    bool clearTarget = false,
    bool clearComputation = false,
    bool clearError = false,
  }) => GraphPathRunState(
    sourceId: clearSource ? null : (sourceId ?? this.sourceId),
    targetId: clearTarget ? null : (targetId ?? this.targetId),
    sourceIsManual: sourceIsManual ?? this.sourceIsManual,
    targetIsManual: targetIsManual ?? this.targetIsManual,
    inferredFromTopology: inferredFromTopology ?? this.inferredFromTopology,
    mode: mode ?? this.mode,
    computation: clearComputation ? null : (computation ?? this.computation),
    stepIndex: stepIndex ?? this.stepIndex,
    alternativeIndex: alternativeIndex ?? this.alternativeIndex,
    error: clearError ? null : (error ?? this.error),
  );
}

class GraphPathRunNotifier extends Notifier<GraphPathRunState> {
  @override
  GraphPathRunState build() {
    ref.listen<Grafo>(grafoProvider, (previous, next) {
      if (previous == next) return;
      if (state.mode == GraphPathMode.kruskalMinimum ||
          state.mode == GraphPathMode.kruskalMaximum) {
        state = state.copyWith(
          clearSource: true,
          clearTarget: true,
          sourceIsManual: false,
          targetIsManual: false,
          clearComputation: true,
          clearError: true,
          stepIndex: 0,
          alternativeIndex: -1,
        );
        return;
      }
      final endpoints = GraphPathEndpoints.suggest(next);
      final keepSource =
          state.sourceIsManual && next.nodos.containsKey(state.sourceId);
      final keepTarget =
          state.targetIsManual && next.nodos.containsKey(state.targetId);
      state = state.copyWith(
        sourceId: keepSource ? state.sourceId : endpoints.sourceId,
        targetId: keepTarget ? state.targetId : endpoints.targetId,
        sourceIsManual: keepSource,
        targetIsManual: keepTarget,
        inferredFromTopology: endpoints.inferredFromTopology,
        clearComputation: true,
        clearError: true,
        stepIndex: 0,
        alternativeIndex: -1,
        clearSource: !keepSource && endpoints.sourceId == null,
        clearTarget: !keepTarget && endpoints.targetId == null,
      );
    });
    return const GraphPathRunState();
  }

  void setSource(String? id) {
    if (state.mode == GraphPathMode.kruskalMinimum ||
        state.mode == GraphPathMode.kruskalMaximum) {
      return;
    }
    final graph = ref.read(grafoProvider);
    if (id != null && !graph.nodos.containsKey(id)) return;
    final suggestion = GraphPathEndpoints.suggest(graph);
    state = state.copyWith(
      sourceId: id ?? suggestion.sourceId,
      sourceIsManual: id != null,
      clearSource: id == null && suggestion.sourceId == null,
      clearComputation: true,
      clearError: true,
      stepIndex: 0,
      alternativeIndex: -1,
    );
  }

  void setTarget(String? id) {
    if (state.mode == GraphPathMode.kruskalMinimum ||
        state.mode == GraphPathMode.kruskalMaximum) {
      return;
    }
    final graph = ref.read(grafoProvider);
    if (id != null && !graph.nodos.containsKey(id)) return;
    final suggestion = GraphPathEndpoints.suggest(graph);
    state = state.copyWith(
      targetId: id ?? suggestion.targetId,
      targetIsManual: id != null,
      clearTarget: id == null && suggestion.targetId == null,
      clearComputation: true,
      clearError: true,
      stepIndex: 0,
      alternativeIndex: -1,
    );
  }

  void setMode(GraphPathMode mode) {
    final kruskal =
        mode == GraphPathMode.kruskalMinimum ||
        mode == GraphPathMode.kruskalMaximum;
    final suggestion = GraphPathEndpoints.suggest(ref.read(grafoProvider));
    state = state.copyWith(
      mode: mode,
      sourceId: kruskal ? null : state.sourceId ?? suggestion.sourceId,
      targetId: kruskal ? null : state.targetId ?? suggestion.targetId,
      clearSource: kruskal,
      clearTarget: kruskal,
      sourceIsManual: kruskal ? false : state.sourceIsManual,
      targetIsManual: kruskal ? false : state.targetIsManual,
      inferredFromTopology: suggestion.inferredFromTopology,
      clearComputation: true,
      clearError: true,
      stepIndex: 0,
      alternativeIndex: -1,
    );
  }

  void reset({bool keepSelections = true}) {
    final graph = ref.read(grafoProvider);
    final suggestion = GraphPathEndpoints.suggest(graph);
    final keepSource =
        keepSelections &&
        state.sourceIsManual &&
        graph.nodos.containsKey(state.sourceId);
    final keepTarget =
        keepSelections &&
        state.targetIsManual &&
        graph.nodos.containsKey(state.targetId);
    state = GraphPathRunState(
      sourceId: keepSource ? state.sourceId : suggestion.sourceId,
      targetId: keepTarget ? state.targetId : suggestion.targetId,
      sourceIsManual: keepSource,
      targetIsManual: keepTarget,
      inferredFromTopology: suggestion.inferredFromTopology,
      mode: state.mode,
    );
  }

  void run(Grafo graph) {
    final kruskal =
        state.mode == GraphPathMode.kruskalMinimum ||
        state.mode == GraphPathMode.kruskalMaximum;
    final suggestion = GraphPathEndpoints.suggest(graph);
    final source = kruskal
        ? null
        : state.sourceIsManual && graph.nodos.containsKey(state.sourceId)
        ? state.sourceId
        : suggestion.sourceId;
    final target = kruskal
        ? null
        : state.targetIsManual && graph.nodos.containsKey(state.targetId)
        ? state.targetId
        : suggestion.targetId;
    state = state.copyWith(
      sourceId: source,
      targetId: target,
      sourceIsManual:
          !kruskal &&
          state.sourceIsManual &&
          graph.nodos.containsKey(state.sourceId),
      targetIsManual:
          !kruskal &&
          state.targetIsManual &&
          graph.nodos.containsKey(state.targetId),
      inferredFromTopology: suggestion.inferredFromTopology,
      clearSource: source == null,
      clearTarget: target == null,
    );
    try {
      final result = switch (state.mode) {
        GraphPathMode.dijkstra => GraphPathSolver.dijkstra(
          graph,
          source ?? '',
          target ?? '',
        ),
        GraphPathMode.longestSimple => GraphPathSolver.longestSimplePath(
          graph,
          source ?? '',
          target ?? '',
        ),
        GraphPathMode.kruskalMinimum => GraphPathSolver.kruskal(
          graph,
          maximum: false,
        ),
        GraphPathMode.kruskalMaximum => GraphPathSolver.kruskal(
          graph,
          maximum: true,
        ),
      };
      state = state.copyWith(
        computation: result,
        stepIndex: result.steps.isEmpty ? 0 : result.steps.length - 1,
        alternativeIndex: -1,
        clearError: true,
      );
    } on GraphPathInputError catch (error) {
      state = state.copyWith(
        clearComputation: true,
        stepIndex: 0,
        alternativeIndex: -1,
        error: error.message,
      );
    }
  }

  void seek(int index) {
    final length = state.computation?.steps.length ?? 0;
    if (length == 0) return;
    state = state.copyWith(stepIndex: index.clamp(0, length - 1));
  }

  void selectAlternative(int index) {
    final count = state.computation?.alternatives.length ?? 0;
    if (index < -1 || index >= count) return;
    state = state.copyWith(alternativeIndex: index);
  }
}

final graphPathRunProvider =
    NotifierProvider<GraphPathRunNotifier, GraphPathRunState>(
      GraphPathRunNotifier.new,
    );

final graphPathHighlightProvider = Provider<AlgorithmHighlight>((ref) {
  final step = ref.watch(graphPathRunProvider).currentStep;
  if (step == null) return const AlgorithmHighlight();
  final state = ref.read(graphPathRunProvider);
  final alternatives =
      state.computation?.alternatives ?? const <GraphPathAlternative>[];
  final isFinal = state.stepIndex == (state.computation?.steps.length ?? 0) - 1;
  if (isFinal &&
      state.alternativeIndex >= 0 &&
      state.alternativeIndex < alternatives.length) {
    final alternative = alternatives[state.alternativeIndex];
    return AlgorithmHighlight(
      algorithmName: 'Dijkstra · camino alternativo',
      nodeIds: alternative.nodeIds.toSet(),
      connectionIds: alternative.edgeIds.toSet(),
    );
  }
  return AlgorithmHighlight(
    algorithmName: 'Dijkstra/Kruskal',
    nodeIds: step.highlightedNodes,
    connectionIds: step.highlightedEdges,
  );
});
