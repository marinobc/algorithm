import 'dart:math';

import '../../../../domain/services/node_name_deduplicator.dart';
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
    OptimizationGoal goal, {
    int origCount = 0,
    int destCount = 0,
  }) {
    if (goal == OptimizationGoal.minimize) return matrix;

    const bigM = 1e6;
    double maxVal = 0.0;
    for (int i = 0; i < matrix.length; i++) {
      for (int j = 0; j < matrix[i].length; j++) {
        // Only evaluate real non-dummy cells to find maxVal
        if (origCount > 0 &&
            destCount > 0 &&
            (i >= origCount || j >= destCount)) {
          continue;
        }
        final cell = matrix[i][j];
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
        // Dummy padded rows or columns carry 0 opportunity cost
        if (origCount > 0 &&
            destCount > 0 &&
            (i >= origCount || j >= destCount)) {
          return 0.0;
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
        dummyAdded = NodeNameDeduplicator.deduplicateName(
          'Ficticio',
          destLabels,
        );
        destLabels.add(dummyAdded);
        dem.add(diff);
        for (int i = 0; i < costs.length; i++) {
          costs[i].add(dummyCost);
        }
      } else {
        final diff = totalDemand - totalSupply;
        dummyAdded = NodeNameDeduplicator.deduplicateName(
          'Ficticio',
          origLabels,
        );
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
    final origCount = problem.origins.length;
    final destCount = problem.destinations.length;
    final n = max(origCount, destCount);

    final origLabels = <String>[];
    for (int i = 0; i < origCount; i++) {
      origLabels.add(problem.origins[i].nombre ?? problem.origins[i].id);
    }
    while (origLabels.length < n) {
      origLabels.add(
        NodeNameDeduplicator.deduplicateName('Ficticio', origLabels),
      );
    }

    final destLabels = <String>[];
    for (int j = 0; j < destCount; j++) {
      destLabels.add(
        problem.destinations[j].nombre ?? problem.destinations[j].id,
      );
    }
    while (destLabels.length < n) {
      destLabels.add(
        NodeNameDeduplicator.deduplicateName('Ficticio', destLabels),
      );
    }

    const bigM = 1e6;
    final costs = List.generate(
      n,
      (i) => List.generate(n, (j) {
        if (i < origCount && j < destCount) {
          final val = problem.costMatrix[i][j];
          if (val.isInfinite || val.isNaN || val >= bigM) {
            return bigM;
          }
          return val;
        }
        return 0.0;
      }),
    );

    final bool wasBalancedWithDummy = origCount != destCount;
    final String? dummyLabelAdded = wasBalancedWithDummy ? 'Ficticio' : null;

    final steps = <StepExplanation>[];
    int stepCounter = 1;

    // 2. Goal Adjustment for Maximization vs Minimization
    final effCosts = TransportationSolverHelper.transformForGoal(
      costs,
      goal,
      origCount: origCount,
      destCount: destCount,
    );
    steps.add(
      StepExplanation(
        stepNumber: stepCounter++,
        title: goal == OptimizationGoal.maximize
            ? 'Paso 1: Transformación para Maximización (Matriz de Oportunidad)'
            : 'Paso 1: Matriz de Costos Inicial',
        description: goal == OptimizationGoal.maximize
            ? r'Para maximizar, se resta cada valor del valor máximo de la matriz: $c^\prime_{ij} = \max(C) - c_{ij}$. El elemento mayor se convierte en 0 y el resto en costos de oportunidad.'
            : r'Matriz de costos original $c_{ij}$ para el problema de minimización.',
        formulaLatex: goal == OptimizationGoal.maximize
            ? r'c^\prime_{ij} = \max_{u,v}(c_{uv}) - c_{ij}'
            : r'C = [c_{ij}]_{n \times n}',
        currentAllocations: List.generate(
          n,
          (r) => List<double>.from(effCosts[r]),
        ),
      ),
    );

    // 3. Step 2: Column Reduction (\alpha_j = \min_{i} c_{ij})
    final alpha = List<double>.filled(n, 0.0);
    final colMinDetails = <String>[];
    for (int j = 0; j < n; j++) {
      double minVal = double.infinity;
      for (int i = 0; i < n; i++) {
        if (effCosts[i][j] < minVal) minVal = effCosts[i][j];
      }
      alpha[j] = minVal;
      colMinDetails.add(
        '\$C_${j + 1}: \\min = ${minVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}\$',
      );
    }

    final colReduced = List.generate(n, (i) => List<double>.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        colReduced[i][j] = max(0.0, effCosts[i][j] - alpha[j]);
      }
    }

    steps.add(
      StepExplanation(
        stepNumber: stepCounter++,
        title: r'Paso 2: Reducción por Columnas ($\alpha_j = \min_{i} c_{ij}$)',
        description:
            'Se determina el valor mínimo de cada columna \$j\$ y se resta celda por celda:\n\n'
            '${colMinDetails.join(' ; ')}\n\n'
            r'Fórmula de sustracción: $c^\prime_{ij} = c_{ij} - \alpha_j$. Toda celda mínima toma valor $0$.',
        formulaLatex:
            r'C^\prime = [c_{ij} - \alpha_j]_{n \times n} \quad \implies \quad \boldsymbol{\alpha} = ['
            '${alpha.map((e) => e.toStringAsFixed(1).replaceAll(RegExp(r'\\.0\$'), '')).join(', ')}]',
        rowVectorAlpha: List<double>.from(alpha),
        currentAllocations: List.generate(
          n,
          (r) => List<double>.from(colReduced[r]),
        ),
      ),
    );

    // 4. Step 3: Row Reduction (\beta_i = \min_{j} c'_{ij})
    final beta = List<double>.filled(n, 0.0);
    final rowMinDetails = <String>[];
    for (int i = 0; i < n; i++) {
      double minVal = colReduced[i].reduce(min);
      beta[i] = minVal;
      rowMinDetails.add(
        '\$R_${i + 1}: \\min = ${minVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}\$',
      );
    }

    final rowReduced = List.generate(n, (i) => List<double>.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        rowReduced[i][j] = max(0.0, colReduced[i][j] - beta[i]);
      }
    }

    steps.add(
      StepExplanation(
        stepNumber: stepCounter++,
        title:
            r'Paso 3: Reducción por Filas ($\beta_i = \min_{j} c^\prime_{ij}$)',
        description:
            'Se examina cada fila \$i\$ de la matriz reducida por columnas \$C^\\prime\$ y se extrae su mínimo:\n\n'
            '${rowMinDetails.join(' ; ')}\n\n'
            r'Fórmula de sustracción: $c^{\prime\prime}_{ij} = c^\prime_{ij} - \beta_i$.',
        formulaLatex:
            r'C^{\prime\prime} = [c^\prime_{ij} - \beta_i]_{n \times n} \quad \implies \quad \boldsymbol{\beta} = ['
            '${beta.map((e) => e.toStringAsFixed(1).replaceAll(RegExp(r'\\.0\$'), '')).join(', ')}]^T',
        colVectorBeta: List<double>.from(beta),
        currentAllocations: List.generate(
          n,
          (r) => List<double>.from(rowReduced[r]),
        ),
      ),
    );

    // 9. Line Cover & Theta Adjustment
    final workingMatrix = List.generate(
      n,
      (i) => List<double>.from(rowReduced[i]),
    );
    var match = _findMaximumMatching(workingMatrix, n);

    int maxIterations = n * n * 2;
    int iteration = 0;

    while (match.length < n && iteration < maxIterations) {
      iteration++;
      final lineCover = _computeMinimumLineCover(workingMatrix, n, match);
      final coveredRows = lineCover.coveredRows;
      final coveredCols = lineCover.coveredCols;

      // Find min uncovered value (\theta > 1e-5)
      double theta = double.infinity;
      for (int i = 0; i < n; i++) {
        if (coveredRows.contains(i)) continue;
        for (int j = 0; j < n; j++) {
          if (coveredCols.contains(j)) continue;
          final val = workingMatrix[i][j];
          if (val > 1e-5 && val < theta) {
            theta = val;
          }
        }
      }

      if (theta.isInfinite || theta <= 1e-5) break;

      // Adjust matrix with \theta
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (!coveredRows.contains(i) && !coveredCols.contains(j)) {
            workingMatrix[i][j] = max(0.0, workingMatrix[i][j] - theta);
          } else if (coveredRows.contains(i) && coveredCols.contains(j)) {
            workingMatrix[i][j] += theta;
          }
        }
      }

      match = _findMaximumMatching(workingMatrix, n);

      steps.add(
        StepExplanation(
          stepNumber: stepCounter++,
          title:
              'Paso $stepCounter: Cobertura de Ceros y Ajuste por Theta (\$\\theta = ${theta.toStringAsFixed(2)}\$)',
          description:
              'Se determinó un cubrimiento mínimo de líneas. El menor elemento no cubierto es \$\\theta = ${theta.toStringAsFixed(2)}\$. Se resta \$\\theta\$ a las celdas no cubiertas y se suma a las intersecciones.',
          formulaLatex:
              r'\theta = \min_{(i,j) \notin R_{cov} \cup C_{cov}} c_{ij}',
          coveredRows: Set<int>.from(coveredRows),
          coveredCols: Set<int>.from(coveredCols),
          thetaValue: theta,
          currentAllocations: List.generate(
            n,
            (r) => List<double>.from(workingMatrix[r]),
          ),
        ),
      );
    }

    // Guarantee full matching of size n for complete allocation table
    if (match.length < n) {
      final unmatchedRows = <int>[];
      final unmatchedCols = <int>[];
      for (int i = 0; i < n; i++) {
        if (!match.containsKey(i)) unmatchedRows.add(i);
      }
      final matchedCols = match.values.toSet();
      for (int j = 0; j < n; j++) {
        if (!matchedCols.contains(j)) unmatchedCols.add(j);
      }
      for (
        int k = 0;
        k < unmatchedRows.length && k < unmatchedCols.length;
        k++
      ) {
        match[unmatchedRows[k]] = unmatchedCols[k];
      }
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
        final actualCost = (i < origCount && j < destCount)
            ? problem.costMatrix[i][j]
            : 0.0;
        if (actualCost.isFinite && actualCost < bigM) {
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
      wasBalancedWithDummy: wasBalancedWithDummy,
      dummyLabelAdded: dummyLabelAdded,
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
