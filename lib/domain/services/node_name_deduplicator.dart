import '../../core/utils/app_logger.dart';

/// Utility class providing global node name deduplication logic across the application.
///
/// Ensures all nodes have unique names. When a name is repeated, appends a ' (n)'
/// suffix (e.g. 'A (1)', 'A (2)') to duplicate instances, while leaving the original
/// instance without signaling.
class NodeNameDeduplicator {
  const NodeNameDeduplicator._();

  /// Deduplicates [desiredName] against a collection of [existingNames].
  ///
  /// If [desiredName] is empty or already unique among [existingNames], it is returned as-is.
  /// If [desiredName] already exists in [existingNames], it appends ' (1)', ' (2)', etc.
  /// until a unique candidate name is found.
  static String deduplicateName(
    String desiredName,
    Iterable<String> existingNames,
  ) {
    final trimmed = desiredName.trim();
    if (trimmed.isEmpty) return trimmed;

    final existingSet = existingNames.map((e) => e.trim()).toSet();

    if (!existingSet.contains(trimmed)) {
      return trimmed;
    }

    int counter = 1;
    while (true) {
      final candidate = '$trimmed ($counter)';
      if (!existingSet.contains(candidate)) {
        AppLogger.d(
          'NodeNameDeduplicator',
          'Name collision for "$trimmed". Assigned unique name "$candidate".',
        );
        return candidate;
      }
      counter++;
    }
  }

  /// Batch deduplicates a list of proposed names for multiple nodes.
  ///
  /// Preserves original names for the first occurrence of each unique string,
  /// and appends ' (1)', ' (2)', etc. for subsequent identical names or collisions.
  /// Option [existingNames] allows deduplicating proposed names against an already existing graph.
  static List<String> deduplicateNameList(
    List<String> proposedNames, {
    Iterable<String> existingNames = const [],
  }) {
    final result = <String>[];
    final seen = existingNames.map((e) => e.trim()).toSet();

    for (final name in proposedNames) {
      final trimmed = name.trim();
      if (!seen.contains(trimmed)) {
        seen.add(trimmed);
        result.add(trimmed);
      } else {
        int counter = 1;
        while (true) {
          final candidate = '$trimmed ($counter)';
          if (!seen.contains(candidate)) {
            seen.add(candidate);
            result.add(candidate);
            break;
          }
          counter++;
        }
      }
    }
    return result;
  }
}
