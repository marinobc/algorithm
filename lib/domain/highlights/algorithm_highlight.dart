import 'package:flutter/material.dart';

/// Modular model representing highlight data produced by any graph algorithm
/// (e.g. Assignment, Shortest Path, Max Flow, Minimum Spanning Tree, BFS/DFS).
class AlgorithmHighlight {
  final String? algorithmName;
  final Set<String> nodeIds;
  final Set<String> connectionIds;
  final Color? highlightColor;
  final Map<String, String> edgeLabels;

  const AlgorithmHighlight({
    this.algorithmName,
    this.nodeIds = const {},
    this.connectionIds = const {},
    this.highlightColor,
    this.edgeLabels = const {},
  });

  bool get isEmpty => nodeIds.isEmpty && connectionIds.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool isNodeHighlighted(String nodeId) => nodeIds.contains(nodeId);
  bool isConnectionHighlighted(String connectionId) =>
      connectionIds.contains(connectionId);
}
