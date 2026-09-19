import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/northwest/domain/models/northwest_models.dart';
import 'package:nodos/algorithms/northwest/domain/solvers/northwest_modi_solver.dart';

void main() {
  const solver = NorthwestModiSolver();
  const costs = [
    [2.0, 7.0, 6.0, 8.0],
    [2.0, 2.0, 6.0, 9.0],
    [9.0, 2.0, 2.0, 2.0],
  ];

  TransportationInput input(TransportationObjective objective) {
    return TransportationInput(
      originIds: const ['o1', 'o2', 'o3'],
      destinationIds: const ['d1', 'd2', 'd3', 'd4'],
      originNames: const ['A', 'B', 'C'],
      destinationNames: const ['D1', 'D2', 'D3', 'D4'],
      costs: costs,
      supplies: const [20, 30, 50],
      demands: const [10, 30, 40, 20],
      objective: objective,
    );
  }

  test('reproduce la solucion inicial y las primeras matrices del docente', () {
    final result = solver.solve(input(TransportationObjective.minimize));

    expect(result.initialAllocations, const [
      [10.0, 10.0, 0.0, 0.0],
      [0.0, 20.0, 10.0, 0.0],
      [0.0, 0.0, 30.0, 20.0],
    ]);
    expect(result.initialObjectiveValue, 290);
    expect(result.iterations.first.opportunityMatrix, const [
      [2.0, 7.0, 11.0, 11.0],
      [-3.0, 2.0, 6.0, 6.0],
      [-7.0, -2.0, 2.0, 2.0],
    ]);
    expect(result.iterations.first.deltas, const [
      [0.0, 0.0, -5.0, -3.0],
      [5.0, 0.0, 0.0, 3.0],
      [16.0, 4.0, 0.0, 0.0],
    ]);
  });

  test('obtiene el minimo esperado mediante MODI', () {
    final result = solver.solve(input(TransportationObjective.minimize));

    expect(result.objectiveValue, 240);
    expect(result.allocations, const [
      [10.0, 0.0, 10.0, 0.0],
      [0.0, 30.0, 0.0, 0.0],
      [0.0, 0.0, 30.0, 20.0],
    ]);
    expect(result.basis, contains(const TransportCell(1, 2)));
    expect(result.basis, isNot(contains(const TransportCell(0, 1))));
  });

  test('obtiene el maximo esperado empezando desde esquina noroeste', () {
    final result = solver.solve(input(TransportationObjective.maximize));

    expect(result.objectiveValue, 550);
    expect(result.allocations, const [
      [0.0, 20.0, 0.0, 0.0],
      [0.0, 0.0, 10.0, 20.0],
      [10.0, 10.0, 30.0, 0.0],
    ]);
    expect(result.iterations.last.deltas, const [
      [-12.0, 0.0, -1.0, -2.0],
      [-11.0, -4.0, 0.0, 0.0],
      [0.0, 0.0, 0.0, -3.0],
    ]);
  });

  test('rechaza problemas desequilibrados', () {
    final invalid = input(TransportationObjective.minimize)
        .copyWith(demands: const [10, 30, 40, 10]);

    expect(() => solver.solve(invalid), throwsArgumentError);
  });
}
