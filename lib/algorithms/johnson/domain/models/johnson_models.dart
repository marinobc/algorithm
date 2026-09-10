class JohnsonNodeResult {
  final String nodeId;
  final String nodeName;
  final double earlyTime;
  final double lateTime;
  final double slack;
  final bool isCritical;

  const JohnsonNodeResult({
    required this.nodeId,
    required this.nodeName,
    required this.earlyTime,
    required this.lateTime,
    required this.slack,
    required this.isCritical,
  });
}

class JohnsonEdgeResult {
  final String connectionId;
  final String sourceId;
  final String targetId;
  final double duration;
  final bool isCritical;

  const JohnsonEdgeResult({
    required this.connectionId,
    required this.sourceId,
    required this.targetId,
    required this.duration,
    required this.isCritical,
  });
}

class JohnsonResult {
  final List<JohnsonNodeResult> nodeResults;
  final List<JohnsonEdgeResult> edgeResults;
  final double totalDuration;
  final Set<String> criticalNodeIds;
  final Set<String> criticalConnectionIds;
  final List<String> criticalPathSequence;

  const JohnsonResult({
    required this.nodeResults,
    required this.edgeResults,
    required this.totalDuration,
    required this.criticalNodeIds,
    required this.criticalConnectionIds,
    required this.criticalPathSequence,
  });
}

class JohnsonValidationResult {
  final bool isValid;
  final String? errorMessage;

  const JohnsonValidationResult({required this.isValid, this.errorMessage});

  const JohnsonValidationResult.valid() : isValid = true, errorMessage = null;

  const JohnsonValidationResult.invalid(this.errorMessage) : isValid = false;
}
