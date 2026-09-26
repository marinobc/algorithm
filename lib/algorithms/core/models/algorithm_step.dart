/// Pure Dart domain model representing an individual step in an algorithm's
/// mathematical breakdown / step-by-step resolution.
class AlgorithmStep {
  /// Step sequence index (1-based).
  final int stepNumber;

  /// Concise title for this step (e.g., 'Asignación Inicial Esquina Noroeste', 'Cálculo de Potenciales u_i y v_j').
  final String title;

  /// Detailed textual explanation of what was computed in this step.
  final String description;

  /// Optional LaTeX formula string (e.g., r'u_i + v_j = c_{ij}').
  final String? formulaLatex;

  /// Optional matrix snapshot representing values at this step (if applicable).
  final List<List<String>>? matrixSnapshot;

  /// IDs of graph nodes involved or highlighted in this step.
  final Set<String> highlightedNodes;

  /// IDs of graph connections involved or highlighted in this step.
  final Set<String> highlightedConnections;

  /// Additional metadata or step-specific metrics (e.g. current objective value Z).
  final Map<String, String> metrics;

  const AlgorithmStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.formulaLatex,
    this.matrixSnapshot,
    this.highlightedNodes = const {},
    this.highlightedConnections = const {},
    this.metrics = const {},
  });
}
