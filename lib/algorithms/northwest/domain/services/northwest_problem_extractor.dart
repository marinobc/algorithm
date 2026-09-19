import '../../../../domain/models/grafo.dart';
import '../models/northwest_models.dart';

class NorthwestRoles {
  static const origin = 'northwest_origin';
  static const destination = 'northwest_destination';
}

class NorthwestMetadata {
  static const originOrder = 'northwest_origin_order';
  static const destinationOrder = 'northwest_destination_order';
  static const objective = 'northwest_objective';
}

class NorthwestValidationResult {
  final TransportationInput? problem;
  final String? errorMessage;

  const NorthwestValidationResult.valid(this.problem) : errorMessage = null;
  const NorthwestValidationResult.invalid(this.errorMessage) : problem = null;

  bool get isValid => problem != null;
}

class NorthwestProblemExtractor {
  static const double tolerance = 1e-9;

  const NorthwestProblemExtractor._();

  static NorthwestValidationResult extract(Grafo graph) {
    final origins = graph.nodos.values
        .where(
          (node) => node.rol == NorthwestRoles.origin || node.rol == 'origen',
        )
        .toList();
    final destinations = graph.nodos.values
        .where(
          (node) =>
              node.rol == NorthwestRoles.destination || node.rol == 'destino',
        )
        .toList();
    if (origins.isEmpty || destinations.isEmpty) {
      return const NorthwestValidationResult.invalid(
        'Configura al menos un origen y un destino.',
      );
    }
    if (origins.length + destinations.length != graph.nodos.length) {
      return const NorthwestValidationResult.invalid(
        'El problema contiene nodos ajenos a la matriz de transporte.',
      );
    }

    final originById = {for (final node in origins) node.id: node};
    final destinationById = {for (final node in destinations) node.id: node};
    final originOrder = _orderedIds(
      graph.metadata[NorthwestMetadata.originOrder],
      originById.keys,
    );
    final destinationOrder = _orderedIds(
      graph.metadata[NorthwestMetadata.destinationOrder],
      destinationById.keys,
    );
    if (originOrder == null || destinationOrder == null) {
      return const NorthwestValidationResult.invalid(
        'No se pudo recuperar el orden de la matriz de transporte.',
      );
    }

    final allNames = [
      ...originOrder.map((id) => originById[id]!.nombre?.trim() ?? ''),
      ...destinationOrder.map(
        (id) => destinationById[id]!.nombre?.trim() ?? '',
      ),
    ];
    if (allNames.any((name) => name.isEmpty) ||
        allNames.toSet().length != allNames.length) {
      return const NorthwestValidationResult.invalid(
        'Los nombres deben estar completos y no pueden repetirse.',
      );
    }

    final supplies = <double>[];
    for (final id in originOrder) {
      final value = originById[id]!.cantidad;
      if (value == null || !value.isFinite || value < 0) {
        return const NorthwestValidationResult.invalid(
          'Todas las disponibilidades deben ser numeros finitos no negativos.',
        );
      }
      supplies.add(value);
    }
    final demands = <double>[];
    for (final id in destinationOrder) {
      final value = destinationById[id]!.cantidad;
      if (value == null || !value.isFinite || value < 0) {
        return const NorthwestValidationResult.invalid(
          'Todas las demandas deben ser numeros finitos no negativos.',
        );
      }
      demands.add(value);
    }

    final costs = <List<double>>[];
    for (final originId in originOrder) {
      final row = <double>[];
      for (final destinationId in destinationOrder) {
        final matches = graph.conexiones.values
            .where(
              (connection) =>
                  connection.nodoOrigenId == originId &&
                  connection.nodoDestinoId == destinationId,
            )
            .toList();
        if (matches.length != 1) {
          return const NorthwestValidationResult.invalid(
            'La red debe contener una conexion por cada celda de costos.',
          );
        }
        final raw = matches.single.atributos
            .where((attribute) => attribute.atributoId == 'attr_valor')
            .firstOrNull
            ?.valor;
        final cost = raw == null ? null : double.tryParse(raw);
        if (cost == null || !cost.isFinite || cost < 0) {
          return const NorthwestValidationResult.invalid(
            'Todos los costos deben ser numeros finitos no negativos.',
          );
        }
        row.add(cost);
      }
      costs.add(row);
    }
    if (graph.conexiones.length != origins.length * destinations.length) {
      return const NorthwestValidationResult.invalid(
        'La red contiene conexiones que no pertenecen a la matriz.',
      );
    }

    var originIds = List<String>.from(originOrder);
    var destinationIds = List<String>.from(destinationOrder);
    var originNames = originOrder.map((id) => originById[id]!.nombre!).toList();
    var destinationNames = destinationOrder
        .map((id) => destinationById[id]!.nombre!)
        .toList();
    var finalSupplies = List<double>.from(supplies);
    var finalDemands = List<double>.from(demands);
    var finalCosts = costs.map((row) => List<double>.from(row)).toList();

    final totalSupply = supplies.fold<double>(0, (sum, value) => sum + value);
    final totalDemand = demands.fold<double>(0, (sum, value) => sum + value);

    if (totalSupply < totalDemand - tolerance) {
      final difference = totalDemand - totalSupply;
      originIds.add('nw_dummy_origin');
      originNames.add('Ficticio');
      finalSupplies.add(difference);
      finalCosts.add(List<double>.filled(destinationOrder.length, 0));
    } else if (totalSupply > totalDemand + tolerance) {
      final difference = totalSupply - totalDemand;
      destinationIds.add('nw_dummy_destination');
      destinationNames.add('Ficticio');
      finalDemands.add(difference);
      for (final row in finalCosts) {
        row.add(0);
      }
    }

    final objective =
        graph.metadata[NorthwestMetadata.objective] ==
            TransportationObjective.maximize.name
        ? TransportationObjective.maximize
        : TransportationObjective.minimize;
    return NorthwestValidationResult.valid(
      TransportationInput(
        originIds: originIds,
        destinationIds: destinationIds,
        originNames: originNames,
        destinationNames: destinationNames,
        costs: finalCosts,
        supplies: finalSupplies,
        demands: finalDemands,
        objective: objective,
      ),
    );
  }

  static List<String>? _orderedIds(String? rawOrder, Iterable<String> ids) {
    final actual = ids.toSet();
    if (rawOrder == null || rawOrder.isEmpty) {
      return actual.toList();
    }
    final ordered = rawOrder.split(',');
    return ordered.length == actual.length &&
            ordered.toSet().containsAll(actual)
        ? ordered
        : actual.toList();
  }
}
