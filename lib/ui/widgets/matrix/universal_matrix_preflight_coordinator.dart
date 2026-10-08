import 'bipartite_matrix_config.dart';

/// Centralized preflight balancing result for matrix screens and algorithms.
class MatrixPreflightResult {
  final List<String> originIds;
  final List<String> originNames;
  final List<String> destinationIds;
  final List<String> destinationNames;
  final bool hasFictitiousOrigin;
  final bool hasFictitiousDestination;
  final int fictitiousOriginCount;
  final int fictitiousDestinationCount;
  final double? totalSupply;
  final double? totalDemand;
  final double? supplyDemandDifference;

  const MatrixPreflightResult({
    required this.originIds,
    required this.originNames,
    required this.destinationIds,
    required this.destinationNames,
    this.hasFictitiousOrigin = false,
    this.hasFictitiousDestination = false,
    this.fictitiousOriginCount = 0,
    this.fictitiousDestinationCount = 0,
    this.totalSupply,
    this.totalDemand,
    this.supplyDemandDifference,
  });

  bool get isBalanced => !hasFictitiousOrigin && !hasFictitiousDestination;
}

/// Universal coordinator for matrix preflight balancing.
/// Performs on-the-spot fictitious row/column calculation for dimension imbalance (e.g. Hungarian Assignment)
/// as well as supply/demand imbalance (e.g. Transportation / Northwest Corner).
class UniversalMatrixPreflightCoordinator {
  const UniversalMatrixPreflightCoordinator();

  /// Calculates preflight balancing given lists of origin/destination IDs, names, and optional supplies/demands.
  static MatrixPreflightResult calculateBalancing({
    required BipartiteMatrixConfig config,
    required List<String> realOriginIds,
    required List<String> realOriginNames,
    required List<String> realDestinationIds,
    required List<String> realDestinationNames,
    List<double?>? supplies,
    List<double?>? demands,
  }) {
    final finalOriginIds = List<String>.from(realOriginIds);
    final finalOriginNames = List<String>.from(realOriginNames);
    final finalDestinationIds = List<String>.from(realDestinationIds);
    final finalDestinationNames = List<String>.from(realDestinationNames);

    bool hasFictOrigin = false;
    bool hasFictDest = false;
    int fictOriginCount = 0;
    int fictDestCount = 0;
    double? totSupply;
    double? totDemand;
    double? diff;

    if (!config.hasFictitiousBalancing) {
      return MatrixPreflightResult(
        originIds: finalOriginIds,
        originNames: finalOriginNames,
        destinationIds: finalDestinationIds,
        destinationNames: finalDestinationNames,
      );
    }

    // 1. Supply / Demand Balancing (Transportation / Northwest Corner)
    if (config.hasSuppliesAndDemands && supplies != null && demands != null) {
      final validSupplies = supplies.whereType<double>().toList();
      final validDemands = demands.whereType<double>().toList();

      if (validSupplies.length == supplies.length &&
          validDemands.length == demands.length) {
        final sSum = validSupplies.fold(0.0, (a, b) => a + b);
        final dSum = validDemands.fold(0.0, (a, b) => a + b);
        totSupply = sSum;
        totDemand = dSum;
        diff = (sSum - dSum).abs();

        if (sSum < dSum) {
          // Supply is lacking: Insert fictitious origin (supplier)
          hasFictOrigin = true;
          fictOriginCount = 1;
          finalOriginIds.add('${config.idPrefix}_dummy_origin_0');
          finalOriginNames.add('Ficticio');
        } else if (dSum < sSum) {
          // Demand is lacking: Insert fictitious destination (consumer)
          hasFictDest = true;
          fictDestCount = 1;
          finalDestinationIds.add('${config.idPrefix}_dummy_dest_0');
          finalDestinationNames.add('Ficticio');
        }
      }
    }
    // 2. Structural Dimension Balancing (Assignment / Hungarian)
    else {
      final originCount = realOriginIds.length;
      final destinationCount = realDestinationIds.length;

      if (originCount != destinationCount) {
        if (originCount < destinationCount) {
          final count = destinationCount - originCount;
          hasFictOrigin = true;
          fictOriginCount = count;
          for (var k = 0; k < count; k++) {
            finalOriginIds.add('${config.idPrefix}_dummy_origin_$k');
            finalOriginNames.add('Ficticio ${k > 0 ? k + 1 : ''}'.trim());
          }
        } else {
          final count = originCount - destinationCount;
          hasFictDest = true;
          fictDestCount = count;
          for (var k = 0; k < count; k++) {
            finalDestinationIds.add('${config.idPrefix}_dummy_dest_$k');
            finalDestinationNames.add('Ficticio ${k > 0 ? k + 1 : ''}'.trim());
          }
        }
      }
    }

    return MatrixPreflightResult(
      originIds: finalOriginIds,
      originNames: finalOriginNames,
      destinationIds: finalDestinationIds,
      destinationNames: finalDestinationNames,
      hasFictitiousOrigin: hasFictOrigin,
      hasFictitiousDestination: hasFictDest,
      fictitiousOriginCount: fictOriginCount,
      fictitiousDestinationCount: fictDestCount,
      totalSupply: totSupply,
      totalDemand: totDemand,
      supplyDemandDifference: diff,
    );
  }
}
