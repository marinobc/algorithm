import 'dart:collection';
import 'dart:math' as math;

import '../models/northwest_models.dart';

class NorthwestModiSolver {
  static const double tolerance = 1e-9;
  static const int maxIterations = 10000;

  const NorthwestModiSolver();

  NorthwestResult solve(TransportationInput input) {
    _validate(input);
    final initial = _buildNorthwestSolution(input);
    var allocations = _copyMatrix(initial.allocations);
    var basis = Set<TransportCell>.from(initial.basis);
    final initialAllocations = _copyMatrix(allocations);
    final initialBasis = Set<TransportCell>.from(basis);
    final initialValue = _objective(allocations, input.costs);
    final iterations = <ModiIteration>[];
    final visitedBases = <String>{};

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final signature = _basisSignature(basis);
      if (!visitedBases.add(signature)) {
        throw StateError('MODI repitio una base y no puede continuar.');
      }

      final potentials = _calculatePotentials(input.costs, basis);
      final opportunity = List.generate(
        input.rowCount,
        (i) => List.generate(
          input.columnCount,
          (j) => potentials.rows[i] + potentials.columns[j],
        ),
      );
      final deltas = List.generate(
        input.rowCount,
        (i) => List.generate(
          input.columnCount,
          (j) => input.costs[i][j] - opportunity[i][j],
        ),
      );
      final entering = _selectEntering(deltas, basis, input.objective);
      final value = _objective(allocations, input.costs);

      if (entering == null) {
        iterations.add(
          ModiIteration(
            number: iteration + 1,
            allocations: _copyMatrix(allocations),
            basis: Set.unmodifiable(basis),
            rowPotentials: List.unmodifiable(potentials.rows),
            columnPotentials: List.unmodifiable(potentials.columns),
            opportunityMatrix: _copyMatrix(opportunity),
            deltas: _copyMatrix(deltas),
            enteringCell: null,
            circuit: const [],
            alpha: null,
            objectiveValue: value,
          ),
        );
        return NorthwestResult(
          initialAllocations: initialAllocations,
          initialBasis: initialBasis,
          initialObjectiveValue: initialValue,
          allocations: _copyMatrix(allocations),
          basis: Set.unmodifiable(basis),
          objectiveValue: value,
          iterations: List.unmodifiable(iterations),
        );
      }

      final circuit = _buildCircuit(
        entering,
        basis,
        input.rowCount,
        input.columnCount,
      );
      final minusCells = <TransportCell>[
        for (var index = 1; index < circuit.length; index += 2) circuit[index],
      ];
      final alpha = minusCells
          .map((cell) => allocations[cell.row][cell.column])
          .reduce(math.min);

      for (var index = 0; index < circuit.length; index++) {
        final cell = circuit[index];
        final next =
            allocations[cell.row][cell.column] +
            (index.isEven ? alpha : -alpha);
        allocations[cell.row][cell.column] = next.abs() <= tolerance ? 0 : next;
      }

      final leavingCandidates =
          minusCells
              .where(
                (cell) => allocations[cell.row][cell.column].abs() <= tolerance,
              )
              .toList()
            ..sort(_compareCells);
      if (leavingCandidates.isEmpty) {
        throw StateError('El circuito MODI no produjo una casilla saliente.');
      }

      basis = Set<TransportCell>.from(basis)
        ..add(entering)
        ..remove(leavingCandidates.first);
      _validateBasis(basis, input.rowCount, input.columnCount);
      _validateFeasibility(allocations, input.supplies, input.demands);

      iterations.add(
        ModiIteration(
          number: iteration + 1,
          allocations: _copyMatrix(allocations),
          basis: Set.unmodifiable(basis),
          rowPotentials: List.unmodifiable(potentials.rows),
          columnPotentials: List.unmodifiable(potentials.columns),
          opportunityMatrix: _copyMatrix(opportunity),
          deltas: _copyMatrix(deltas),
          enteringCell: entering,
          circuit: List.unmodifiable(circuit),
          alpha: alpha,
          objectiveValue: _objective(allocations, input.costs),
        ),
      );
    }

    throw StateError('MODI excedio el limite de $maxIterations iteraciones.');
  }

  _InitialSolution _buildNorthwestSolution(TransportationInput input) {
    final remainingSupply = List<double>.from(input.supplies);
    final remainingDemand = List<double>.from(input.demands);
    final allocations = List.generate(
      input.rowCount,
      (_) => List<double>.filled(input.columnCount, 0),
    );
    final basis = <TransportCell>{};
    var row = 0;
    var column = 0;

    while (row < input.rowCount && column < input.columnCount) {
      final quantity = math.min(remainingSupply[row], remainingDemand[column]);
      allocations[row][column] = quantity;
      basis.add(TransportCell(row, column));
      remainingSupply[row] -= quantity;
      remainingDemand[column] -= quantity;
      final supplyDone = remainingSupply[row].abs() <= tolerance;
      final demandDone = remainingDemand[column].abs() <= tolerance;

      if (supplyDone && demandDone) {
        row++;
        column++;
      } else if (supplyDone) {
        row++;
      } else if (demandDone) {
        column++;
      }
    }

    _completeDegenerateBasis(basis, input.rowCount, input.columnCount);
    _validateBasis(basis, input.rowCount, input.columnCount);
    return _InitialSolution(allocations, basis);
  }

  void _completeDegenerateBasis(
    Set<TransportCell> basis,
    int rows,
    int columns,
  ) {
    final components = _DisjointSet(rows + columns);
    final ordered = basis.toList()..sort(_compareCells);
    for (final cell in ordered) {
      components.union(cell.row, rows + cell.column);
    }
    for (var i = 0; i < rows && basis.length < rows + columns - 1; i++) {
      for (var j = 0; j < columns && basis.length < rows + columns - 1; j++) {
        final cell = TransportCell(i, j);
        if (basis.contains(cell)) continue;
        if (components.union(i, rows + j)) basis.add(cell);
      }
    }
  }

  _Potentials _calculatePotentials(
    List<List<double>> costs,
    Set<TransportCell> basis,
  ) {
    final rows = List<double?>.filled(costs.length, null);
    final columns = List<double?>.filled(costs.first.length, null);
    columns[0] = 0;
    var changed = true;
    while (changed) {
      changed = false;
      for (final cell in basis) {
        final rowValue = rows[cell.row];
        final columnValue = columns[cell.column];
        if (rowValue == null && columnValue != null) {
          rows[cell.row] = costs[cell.row][cell.column] - columnValue;
          changed = true;
        } else if (rowValue != null && columnValue == null) {
          columns[cell.column] = costs[cell.row][cell.column] - rowValue;
          changed = true;
        }
      }
    }
    if (rows.any((value) => value == null) ||
        columns.any((value) => value == null)) {
      throw StateError(
        'La base no permite calcular todos los potenciales MODI.',
      );
    }
    return _Potentials(rows.cast<double>(), columns.cast<double>());
  }

  TransportCell? _selectEntering(
    List<List<double>> deltas,
    Set<TransportCell> basis,
    TransportationObjective objective,
  ) {
    TransportCell? selected;
    double? best;
    for (var i = 0; i < deltas.length; i++) {
      for (var j = 0; j < deltas[i].length; j++) {
        final cell = TransportCell(i, j);
        if (basis.contains(cell)) continue;
        final delta = deltas[i][j];
        final improves = objective == TransportationObjective.minimize
            ? delta < -tolerance
            : delta > tolerance;
        if (!improves) continue;
        if (best == null ||
            (objective == TransportationObjective.minimize
                ? delta < best - tolerance
                : delta > best + tolerance)) {
          best = delta;
          selected = cell;
        }
      }
    }
    return selected;
  }

  List<TransportCell> _buildCircuit(
    TransportCell entering,
    Set<TransportCell> basis,
    int rows,
    int columns,
  ) {
    final vertexCount = rows + columns;
    final adjacency = List.generate(vertexCount, (_) => <_GraphEdge>[]);
    for (final cell in basis) {
      final rowVertex = cell.row;
      final columnVertex = rows + cell.column;
      adjacency[rowVertex].add(_GraphEdge(columnVertex, cell));
      adjacency[columnVertex].add(_GraphEdge(rowVertex, cell));
    }
    for (final edges in adjacency) {
      edges.sort((a, b) => _compareCells(a.cell, b.cell));
    }

    final start = entering.row;
    final target = rows + entering.column;
    final parents = List<int?>.filled(vertexCount, null);
    final parentCells = List<TransportCell?>.filled(vertexCount, null);
    final queue = Queue<int>()..add(start);
    parents[start] = start;
    while (queue.isNotEmpty && parents[target] == null) {
      final vertex = queue.removeFirst();
      for (final edge in adjacency[vertex]) {
        if (parents[edge.vertex] != null) continue;
        parents[edge.vertex] = vertex;
        parentCells[edge.vertex] = edge.cell;
        queue.add(edge.vertex);
      }
    }
    if (parents[target] == null) {
      throw StateError('No se pudo construir el circuito cerrado de MODI.');
    }

    final path = <TransportCell>[];
    var current = target;
    while (current != start) {
      path.add(parentCells[current]!);
      current = parents[current]!;
    }
    final circuit = <TransportCell>[entering, ...path];
    if (circuit.length < 4 || circuit.length.isOdd) {
      throw StateError('El circuito MODI calculado no es alternante.');
    }
    return circuit;
  }

  void _validate(TransportationInput input) {
    if (input.rowCount == 0 || input.columnCount == 0) {
      throw ArgumentError('Debe existir al menos un origen y un destino.');
    }
    if (input.originIds.length != input.rowCount ||
        input.originNames.length != input.rowCount ||
        input.destinationIds.length != input.columnCount ||
        input.destinationNames.length != input.columnCount ||
        input.costs.length != input.rowCount ||
        input.costs.any((row) => row.length != input.columnCount)) {
      throw ArgumentError('Las dimensiones del problema no son compatibles.');
    }
    final allNumbers = <double>[
      ...input.supplies,
      ...input.demands,
      ...input.costs.expand((row) => row),
    ];
    if (allNumbers.any((value) => !value.isFinite)) {
      throw ArgumentError('Todos los valores deben ser numeros finitos.');
    }
    if (input.supplies.any((value) => value < 0) ||
        input.demands.any((value) => value < 0)) {
      throw ArgumentError('Las ofertas y demandas no pueden ser negativas.');
    }
    if ((input.totalSupply - input.totalDemand).abs() > tolerance) {
      throw ArgumentError(
        'El problema no esta equilibrado: oferta ${input.totalSupply}, '
        'demanda ${input.totalDemand}.',
      );
    }
  }

  void _validateBasis(Set<TransportCell> basis, int rows, int columns) {
    if (basis.length != rows + columns - 1) {
      throw StateError('La base debe contener m+n-1 casillas.');
    }
    final components = _DisjointSet(rows + columns);
    for (final cell in basis) {
      if (!components.union(cell.row, rows + cell.column)) {
        throw StateError('La base contiene un ciclo.');
      }
    }
  }

  void _validateFeasibility(
    List<List<double>> allocations,
    List<double> supplies,
    List<double> demands,
  ) {
    for (var i = 0; i < allocations.length; i++) {
      if (allocations[i].any((value) => value < -tolerance) ||
          (allocations[i].fold<double>(0, (sum, value) => sum + value) -
                      supplies[i])
                  .abs() >
              tolerance) {
        throw StateError('La distribucion MODI dejo de ser factible.');
      }
    }
    for (var j = 0; j < demands.length; j++) {
      var sum = 0.0;
      for (final row in allocations) {
        sum += row[j];
      }
      if ((sum - demands[j]).abs() > tolerance) {
        throw StateError('La distribucion MODI dejo de ser factible.');
      }
    }
  }

  double _objective(List<List<double>> allocations, List<List<double>> costs) {
    var result = 0.0;
    for (var i = 0; i < allocations.length; i++) {
      for (var j = 0; j < allocations[i].length; j++) {
        result += allocations[i][j] * costs[i][j];
      }
    }
    return result;
  }

  String _basisSignature(Set<TransportCell> basis) {
    final cells = basis.toList()..sort(_compareCells);
    return cells.map((cell) => '${cell.row}:${cell.column}').join('|');
  }

  static int _compareCells(TransportCell a, TransportCell b) {
    final rowComparison = a.row.compareTo(b.row);
    return rowComparison != 0 ? rowComparison : a.column.compareTo(b.column);
  }

  static List<List<double>> _copyMatrix(List<List<double>> matrix) =>
      matrix.map((row) => List<double>.from(row)).toList();
}

class _InitialSolution {
  final List<List<double>> allocations;
  final Set<TransportCell> basis;

  const _InitialSolution(this.allocations, this.basis);
}

class _Potentials {
  final List<double> rows;
  final List<double> columns;

  const _Potentials(this.rows, this.columns);
}

class _GraphEdge {
  final int vertex;
  final TransportCell cell;

  const _GraphEdge(this.vertex, this.cell);
}

class _DisjointSet {
  final List<int> _parent;
  final List<int> _rank;

  _DisjointSet(int size)
    : _parent = List.generate(size, (index) => index),
      _rank = List<int>.filled(size, 0);

  int find(int value) {
    if (_parent[value] != value) _parent[value] = find(_parent[value]);
    return _parent[value];
  }

  bool union(int first, int second) {
    var rootA = find(first);
    var rootB = find(second);
    if (rootA == rootB) return false;
    if (_rank[rootA] < _rank[rootB]) {
      final temporary = rootA;
      rootA = rootB;
      rootB = temporary;
    }
    _parent[rootB] = rootA;
    if (_rank[rootA] == _rank[rootB]) _rank[rootA]++;
    return true;
  }
}
