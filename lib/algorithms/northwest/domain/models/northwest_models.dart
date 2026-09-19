enum TransportationObjective { minimize, maximize }

extension TransportationObjectiveLabel on TransportationObjective {
  String get displayName => switch (this) {
    TransportationObjective.minimize => 'Minimizar costo',
    TransportationObjective.maximize => 'Maximizar beneficio',
  };
}

class TransportationInput {
  final List<String> originIds;
  final List<String> destinationIds;
  final List<String> originNames;
  final List<String> destinationNames;
  final List<List<double>> costs;
  final List<double> supplies;
  final List<double> demands;
  final TransportationObjective objective;

  const TransportationInput({
    required this.originIds,
    required this.destinationIds,
    required this.originNames,
    required this.destinationNames,
    required this.costs,
    required this.supplies,
    required this.demands,
    this.objective = TransportationObjective.minimize,
  });

  int get rowCount => supplies.length;
  int get columnCount => demands.length;
  double get totalSupply => supplies.fold(0, (sum, value) => sum + value);
  double get totalDemand => demands.fold(0, (sum, value) => sum + value);

  TransportationInput copyWith({
    List<String>? originIds,
    List<String>? destinationIds,
    List<String>? originNames,
    List<String>? destinationNames,
    List<List<double>>? costs,
    List<double>? supplies,
    List<double>? demands,
    TransportationObjective? objective,
  }) {
    return TransportationInput(
      originIds: originIds ?? this.originIds,
      destinationIds: destinationIds ?? this.destinationIds,
      originNames: originNames ?? this.originNames,
      destinationNames: destinationNames ?? this.destinationNames,
      costs: costs ?? this.costs,
      supplies: supplies ?? this.supplies,
      demands: demands ?? this.demands,
      objective: objective ?? this.objective,
    );
  }
}

class TransportCell {
  final int row;
  final int column;

  const TransportCell(this.row, this.column);

  @override
  bool operator ==(Object other) =>
      other is TransportCell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

class ModiIteration {
  final int number;
  final List<List<double>> allocations;
  final Set<TransportCell> basis;
  final List<double> rowPotentials;
  final List<double> columnPotentials;
  final List<List<double>> opportunityMatrix;
  final List<List<double>> deltas;
  final TransportCell? enteringCell;
  final List<TransportCell> circuit;
  final double? alpha;
  final double objectiveValue;

  const ModiIteration({
    required this.number,
    required this.allocations,
    required this.basis,
    required this.rowPotentials,
    required this.columnPotentials,
    required this.opportunityMatrix,
    required this.deltas,
    required this.enteringCell,
    required this.circuit,
    required this.alpha,
    required this.objectiveValue,
  });

  bool get isOptimal => enteringCell == null;
}

class NorthwestResult {
  final List<List<double>> initialAllocations;
  final Set<TransportCell> initialBasis;
  final double initialObjectiveValue;
  final List<List<double>> allocations;
  final Set<TransportCell> basis;
  final double objectiveValue;
  final List<ModiIteration> iterations;

  const NorthwestResult({
    required this.initialAllocations,
    required this.initialBasis,
    required this.initialObjectiveValue,
    required this.allocations,
    required this.basis,
    required this.objectiveValue,
    required this.iterations,
  });
}
