import '../../../../domain/models/nodo.dart';

enum TransportationMethod { hungarian }

extension TransportationMethodExtension on TransportationMethod {
  String get displayName {
    switch (this) {
      case TransportationMethod.hungarian:
        return 'Algoritmo de Asignación';
    }
  }
}

enum OptimizationGoal { minimize, maximize }

extension OptimizationGoalExtension on OptimizationGoal {
  String get displayName {
    switch (this) {
      case OptimizationGoal.minimize:
        return 'Minimizar Costo';
      case OptimizationGoal.maximize:
        return 'Maximizar Beneficio';
    }
  }
}

class TransportationProblemData {
  final List<Nodo> origins;
  final List<Nodo> destinations;
  final List<double> supplies;
  final List<double> demands;

  /// Matrix cost[i][j] representing cost or profit between origin i and destination j.
  /// double.infinity or NaN represents no direct connection between i and j.
  final List<List<double>> costMatrix;
  final bool isBalanced;
  final double totalSupply;
  final double totalDemand;

  const TransportationProblemData({
    required this.origins,
    required this.destinations,
    required this.supplies,
    required this.demands,
    required this.costMatrix,
    required this.isBalanced,
    required this.totalSupply,
    required this.totalDemand,
  });
}

class AllocationCell {
  final int originIndex;
  final int destinationIndex;
  final double allocatedQuantity;
  final double unitCost;
  final bool isDummyOrigin;
  final bool isDummyDestination;

  const AllocationCell({
    required this.originIndex,
    required this.destinationIndex,
    required this.allocatedQuantity,
    required this.unitCost,
    this.isDummyOrigin = false,
    this.isDummyDestination = false,
  });

  double get totalCellCost =>
      allocatedQuantity * (unitCost.isFinite ? unitCost : 0.0);
}

class StepExplanation {
  final int stepNumber;
  final String title;
  final String description;
  final List<List<double>>? currentAllocations;

  const StepExplanation({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.currentAllocations,
  });
}

class TransportationResult {
  final TransportationMethod method;
  final OptimizationGoal goal;
  final List<String> originLabels;
  final List<String> destinationLabels;
  final List<double> supplies;
  final List<double> demands;
  final List<List<double>> costMatrix;
  final List<List<double>> allocationMatrix;
  final double totalCost;
  final List<StepExplanation> steps;
  final bool wasBalancedWithDummy;
  final String? dummyLabelAdded;

  const TransportationResult({
    required this.method,
    required this.goal,
    required this.originLabels,
    required this.destinationLabels,
    required this.supplies,
    required this.demands,
    required this.costMatrix,
    required this.allocationMatrix,
    required this.totalCost,
    required this.steps,
    this.wasBalancedWithDummy = false,
    this.dummyLabelAdded,
  });
}
