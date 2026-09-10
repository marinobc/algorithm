import 'dart:math';

import '../models/assignment_models.dart';

abstract class ITransportationSolver {
  TransportationResult solve({
    required TransportationProblemData problem,
    required TransportationMethod method,
    required OptimizationGoal goal,
  });
}

class TransportationSolverHelper {
  /// Transforms maximizing cost matrix into minimizing by subtracting from max cost.
  /// Preserves bigM penalties for unconnected/impossible edges.
  static List<List<double>> transformForGoal(
    List<List<double>> matrix,
    OptimizationGoal goal,
  ) {
    if (goal == OptimizationGoal.minimize) return matrix;

    const bigM = 1e6;
    double maxVal = 0.0;
    for (final row in matrix) {
      for (final cell in row) {
        if (cell.isFinite && cell < bigM && cell > maxVal) {
          maxVal = cell;
        }
      }
    }

    final numRows = matrix.length;
    final numCols = matrix[0].length;
    final transformed = List.generate(
      numRows,
      (i) => List.generate(numCols, (j) {
        final val = matrix[i][j];
        if (val >= bigM || val.isInfinite) {
          return bigM; // Keep penalty high so Hungarian never chooses missing edges
        }
        return maxVal - val;
      }),
    );
    return transformed;
  }

  /// Balance problem with dummy origin or destination if needed
  static BalancedData balanceProblem(
    List<String> origins,
    List<String> destinations,
    List<double> supplies,
    List<double> demands,
    List<List<double>> costMatrix,
  ) {
    final origLabels = List<String>.from(origins);
    final destLabels = List<String>.from(destinations);
    final supp = List<double>.from(supplies);
    final dem = List<double>.from(demands);
    final costs = List.generate(
      costMatrix.length,
      (i) => List<double>.from(costMatrix[i]),
    );

    final totalSupply = supp.fold(0.0, (a, b) => a + b);
    final totalDemand = dem.fold(0.0, (a, b) => a + b);

    bool wasBalanced = false;
    String? dummyAdded;

    const dummyCost = 0.0;
    const bigM = 1e6; // Big penalty cost for impossible connections

    if ((totalSupply - totalDemand).abs() > 1e-5) {
      wasBalanced = true;
      if (totalSupply > totalDemand) {
        final diff = totalSupply - totalDemand;
        dummyAdded = '0 (Destino)';
        destLabels.add(dummyAdded);
        dem.add(diff);
        for (int i = 0; i < costs.length; i++) {
          costs[i].add(dummyCost);
        }
      } else {
        final diff = totalDemand - totalSupply;
        dummyAdded = '0 (Origen)';
        origLabels.add(dummyAdded);
        supp.add(diff);
        final dummyRow = List<double>.filled(destLabels.length, dummyCost);
        costs.add(dummyRow);
      }
    }

    // Replace double.infinity with BigM in costs
    for (int i = 0; i < costs.length; i++) {
      for (int j = 0; j < costs[i].length; j++) {
        if (costs[i][j].isInfinite) {
          costs[i][j] = bigM;
        }
      }
    }

    return BalancedData(
      originLabels: origLabels,
      destinationLabels: destLabels,
      supplies: supp,
      demands: dem,
      costMatrix: costs,
      wasBalanced: wasBalanced,
      dummyAddedLabel: dummyAdded,
    );
  }
}

class BalancedData {
  final List<String> originLabels;
  final List<String> destinationLabels;
  final List<double> supplies;
  final List<double> demands;
  final List<List<double>> costMatrix;
  final bool wasBalanced;
  final String? dummyAddedLabel;

  BalancedData({
    required this.originLabels,
    required this.destinationLabels,
    required this.supplies,
    required this.demands,
    required this.costMatrix,
    required this.wasBalanced,
    this.dummyAddedLabel,
  });
}

class HungarianAssignmentSolver implements ITransportationSolver {
  @override
  TransportationResult solve({
    required TransportationProblemData problem,
    required TransportationMethod method,
    required OptimizationGoal goal,
  }) {
    final origNames = problem.origins.map((o) => o.nombre ?? o.id).toList();
    final destNames = problem.destinations
        .map((d) => d.nombre ?? d.id)
        .toList();

    // 1. Balance/Pad rectangular matrix to square N x N (N = max(M, N)) with 0 cost for dummy nodes
    final balanced = TransportationSolverHelper.balanceProblem(
      origNames,
      destNames,
      problem.supplies,
      problem.demands,
      problem.costMatrix,
    );

    final n = max(
      balanced.originLabels.length,
      balanced.destinationLabels.length,
    );
    final origLabels = List<String>.from(balanced.originLabels);
    final destLabels = List<String>.from(balanced.destinationLabels);
    final costs = List.generate(
      n,
      (i) => List<double>.from(balanced.costMatrix[i]),
    );

    // Pad matrix up to square n x n if origins or destinations lengths differ
    while (origLabels.length < n) {
      origLabels.add('0 (Origen ${origLabels.length + 1})');
      costs.add(List<double>.filled(n, 0.0));
    }
    while (destLabels.length < n) {
      destLabels.add('0 (Destino ${destLabels.length + 1})');
      for (int i = 0; i < n; i++) {
        costs[i].add(0.0);
      }
    }

    final steps = <StepExplanation>[];
    int stepCounter = 1;

    // 2. Goal Adjustment for Maximization vs Minimization
    final effCosts = TransportationSolverHelper.transformForGoal(costs, goal);
    steps.add(
      StepExplanation(
        stepNumber: stepCounter++,
        title: 'Paso 1: Matriz de Costos Inicial',
        description: goal == OptimizationGoal.maximize
            ? 'Matriz ajustada para maximización.'
            : 'Matriz inicial de costos.',
      ),
    );

    // 3. Step 1: Row Reduction (\alpha_i)
    final rowReduced = List.generate(n, (i) => List<double>.from(effCosts[i]));
    final alpha = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double minVal = rowReduced[i].reduce(min);
      alpha[i] = minVal;
      for (int j = 0; j < n; j++) {
        rowReduced[i][j] -= minVal;
      }
    }
    steps.add(
      StepExplanation(
        stepNumber: stepCounter++,
        title: 'Paso 2: Reducción por Filas (Alpha)',
        description:
            'Se resta el mínimo de cada fila a sus elementos (Alpha_i).',
        currentAllocations: List.generate(
          n,
          (r) => List<double>.from(rowReduced[r]),
        ),
      ),
    );

    // 4. Step 2: Column Reduction (\beta_j)
    final colReduced = List.generate(
      n,
      (i) => List<double>.from(rowReduced[i]),
    );
    final beta = List<double>.filled(n, 0.0);
    for (int j = 0; j < n; j++) {
      double minVal = double.infinity;
      for (int i = 0; i < n; i++) {
        if (colReduced[i][j] < minVal) minVal = colReduced[i][j];
      }
      beta[j] = minVal;
      for (int i = 0; i < n; i++) {
        colReduced[i][j] -= minVal;
      }
    }
    steps.add(
      StepExplanation(
        stepNumber: stepCounter++,
        title: 'Paso 3: Reducción por Columnas (Beta)',
        description:
            'Se resta el mínimo de cada columna a sus elementos (Beta_j).',
        currentAllocations: List.generate(
          n,
          (r) => List<double>.from(colReduced[r]),
        ),
      ),
    );

    // 5. Step 3: Line Cover & Theta Adjustment until N lines cover all zeros
    final workingMatrix = List.generate(
      n,
      (i) => List<double>.from(colReduced[i]),
    );
    var match = _findMaximumMatching(workingMatrix, n);

    while (match.length < n) {
      final lineCover = _computeMinimumLineCover(workingMatrix, n, match);
      final coveredRows = lineCover.coveredRows;
      final coveredCols = lineCover.coveredCols;

      // Find min uncovered value (\theta)
      double theta = double.infinity;
      for (int i = 0; i < n; i++) {
        if (coveredRows.contains(i)) continue;
        for (int j = 0; j < n; j++) {
          if (coveredCols.contains(j)) continue;
          if (workingMatrix[i][j] < theta) theta = workingMatrix[i][j];
        }
      }

      if (theta.isInfinite || theta <= 0) break;

      // Adjust matrix with \theta
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (!coveredRows.contains(i) && !coveredCols.contains(j)) {
            workingMatrix[i][j] -= theta;
          } else if (coveredRows.contains(i) && coveredCols.contains(j)) {
            workingMatrix[i][j] += theta;
          }
        }
      }

      match = _findMaximumMatching(workingMatrix, n);
    }

    // 6. Build final allocation matrix n x n
    final allocationMatrix = List.generate(
      n,
      (_) => List<double>.filled(n, 0.0),
    );
    double totalCost = 0.0;

    for (int i = 0; i < n; i++) {
      final j = match[i];
      if (j != null && j >= 0 && j < n) {
        allocationMatrix[i][j] = 1.0;
        final actualCost = (i < costs.length && j < costs[i].length)
            ? costs[i][j]
            : 0.0;
        if (actualCost.isFinite) {
          totalCost += actualCost;
        }
      }
    }

    return TransportationResult(
      method: method,
      goal: goal,
      originLabels: origLabels,
      destinationLabels: destLabels,
      supplies: List<double>.filled(n, 1.0),
      demands: List<double>.filled(n, 1.0),
      costMatrix: costs,
      allocationMatrix: allocationMatrix,
      totalCost: totalCost,
      steps: steps,
      wasBalancedWithDummy:
          balanced.wasBalanced ||
          origLabels.length > problem.origins.length ||
          destLabels.length > problem.destinations.length,
      dummyLabelAdded: balanced.dummyAddedLabel,
    );
  }

  Map<int, int> _findMaximumMatching(List<List<double>> matrix, int n) {
    final match = <int, int>{};
    final usedCols = <int>{};

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (!usedCols.contains(j) && matrix[i][j].abs() < 1e-5) {
          match[i] = j;
          usedCols.add(j);
          break;
        }
      }
    }

    // Augmenting path algorithm for maximum bipartite matching on zeros
    for (int i = 0; i < n; i++) {
      if (!match.containsKey(i)) {
        final visited = <int>{};
        _bpm(i, matrix, n, match, visited);
      }
    }

    return match;
  }

  bool _bpm(
    int u,
    List<List<double>> matrix,
    int n,
    Map<int, int> matchR,
    Set<int> visited,
  ) {
    for (int v = 0; v < n; v++) {
      if (matrix[u][v].abs() < 1e-5 && !visited.contains(v)) {
        visited.add(v);
        final currentMatch = matchR.entries
            .firstWhere(
              (e) => e.value == v,
              orElse: () => const MapEntry(-1, -1),
            )
            .key;
        if (currentMatch == -1 ||
            _bpm(currentMatch, matrix, n, matchR, visited)) {
          matchR[u] = v;
          return true;
        }
      }
    }
    return false;
  }

  _LineCover _computeMinimumLineCover(
    List<List<double>> matrix,
    int n,
    Map<int, int> match,
  ) {
    final markedRows = <int>{};
    final markedCols = <int>{};

    for (int i = 0; i < n; i++) {
      if (!match.containsKey(i)) markedRows.add(i);
    }

    bool newlyMarked = true;
    while (newlyMarked) {
      newlyMarked = false;
      for (final r in markedRows.toList()) {
        for (int c = 0; c < n; c++) {
          if (matrix[r][c].abs() < 1e-5 && !markedCols.contains(c)) {
            markedCols.add(c);
            newlyMarked = true;
          }
        }
      }
      for (final c in markedCols.toList()) {
        final r = match.entries
            .firstWhere(
              (e) => e.value == c,
              orElse: () => const MapEntry(-1, -1),
            )
            .key;
        if (r != -1 && !markedRows.contains(r)) {
          markedRows.add(r);
          newlyMarked = true;
        }
      }
    }

    final coveredRows = <int>{};
    final coveredCols = Set<int>.from(markedCols);

    for (int i = 0; i < n; i++) {
      if (!markedRows.contains(i)) coveredRows.add(i);
    }

    return _LineCover(coveredRows, coveredCols);
  }
}

class _LineCover {
  final Set<int> coveredRows;
  final Set<int> coveredCols;

  _LineCover(this.coveredRows, this.coveredCols);
}
