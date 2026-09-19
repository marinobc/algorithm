/// Configuration contract for bipartite / cost matrix input screens.
abstract class BipartiteMatrixConfig {
  String get title;
  String get subtitle;
  String get originHeaderTitle;
  String get destinationHeaderTitle;
  String get originRole;
  String get destinationRole;
  int get defaultOriginColor;
  int get defaultDestinationColor;
  String get costAttributeId;
  String get costCellHint;
  String get defaultTypeAlgorithm;

  /// Whether this problem has supplies ($a_i$) and demands ($b_j$).
  /// True for Transportation / Northwest, False for pure Assignment.
  bool get hasSuppliesAndDemands;

  /// Whether to support fictitious balancing columns / rows automatically.
  bool get hasFictitiousBalancing;

  /// Prefix used for generating unique IDs
  String get idPrefix;
}
