import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../models/assignment_models.dart';
import 'assignment_validator.dart';

class AssignmentMatrixExtractor {
  static TransportationProblemData extract(
    Grafo grafo,
    TransportationValidationResult validation, {
    Map<String, double>? customSupplies,
    Map<String, double>? customDemands,
  }) {
    final origins = List<Nodo>.from(validation.origins);
    final destinations = List<Nodo>.from(validation.destinations);

    // Default supply = 1.0 for assignment, or parse from custom map / default 10.0
    final supplies = origins.map((o) {
      if (customSupplies != null && customSupplies.containsKey(o.id)) {
        return customSupplies[o.id]!;
      }
      return 1.0;
    }).toList();

    final demands = destinations.map((d) {
      if (customDemands != null && customDemands.containsKey(d.id)) {
        return customDemands[d.id]!;
      }
      return 1.0;
    }).toList();

    final costMatrix = List.generate(
      origins.length,
      (i) => List.generate(destinations.length, (j) => double.infinity),
    );

    for (int i = 0; i < origins.length; i++) {
      final o = origins[i];
      for (int j = 0; j < destinations.length; j++) {
        final d = destinations[j];

        // Find connection from o to d
        final conn = grafo.conexiones.values.firstWhere(
          (c) => c.nodoOrigenId == o.id && c.nodoDestinoId == d.id,
          orElse: () => const Conexion(
            id: '',
            nodoOrigenId: '',
            nodoDestinoId: '',
            colorValue: 0,
          ),
        );

        if (conn.id.isNotEmpty) {
          final attrVal = conn.atributos.firstWhere(
            (a) => a.atributoId == 'attr_valor',
            orElse: () => conn.atributos.isNotEmpty
                ? conn.atributos.first
                : const AtributoValor(atributoId: '', valor: '1'),
          );
          final parsed = double.tryParse(attrVal.valor);
          costMatrix[i][j] = (parsed != null && parsed >= 0) ? parsed : 1.0;
        }
      }
    }

    final totalSupply = supplies.fold(0.0, (acc, s) => acc + s);
    final totalDemand = demands.fold(0.0, (acc, d) => acc + d);
    final isBalanced = (totalSupply - totalDemand).abs() < 1e-5;

    return TransportationProblemData(
      origins: origins,
      destinations: destinations,
      supplies: supplies,
      demands: demands,
      costMatrix: costMatrix,
      isBalanced: isBalanced,
      totalSupply: totalSupply,
      totalDemand: totalDemand,
    );
  }
}
