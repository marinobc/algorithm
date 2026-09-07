import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';

class TransportationValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<Nodo> origins;
  final List<Nodo> destinations;

  const TransportationValidationResult({
    required this.isValid,
    this.errorMessage,
    this.origins = const [],
    this.destinations = const [],
  });
}

class TransportationValidator {
  /// Validates that the graph is bipartite formatted for transportation/assignment:
  /// - Every origin node must have in-degree = 0 and out-degree > 0.
  /// - Every destination node must have out-degree = 0 and in-degree > 0.
  /// - No connections between two origins.
  /// - No connections between two destinations.
  /// - No bidirectional connections or self-loops.
  /// - If any condition fails, returns exact message starting with:
  ///   "No se puede aplicar el algoritmo, modifique [detalles]"
  static TransportationValidationResult validate(Grafo grafo) {
    if (grafo.nodos.isEmpty) {
      return const TransportationValidationResult(
        isValid: false,
        errorMessage: 'No se puede aplicar el algoritmo, modifique el lienzo agregando nodos y conexiones.',
      );
    }

    // 1. Check for bidirectional edges or self-loops first
    for (final conexion in grafo.conexiones.values) {
      final origNode = grafo.nodos[conexion.nodoOrigenId];
      final destNode = grafo.nodos[conexion.nodoDestinoId];
      final origName = origNode?.nombre ?? conexion.nodoOrigenId;
      final destName = destNode?.nombre ?? conexion.nodoDestinoId;

      if (conexion.nodoOrigenId == conexion.nodoDestinoId) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique el bucle en "$origName" (no se permiten auto-conexiones).',
        );
      }

      if (conexion.direccion == Direccion.bidireccional) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique la conexión bidireccional entre "$origName" y "$destName".',
        );
      }

      if (conexion.direccion == Direccion.ninguna) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique la conexión sin dirección entre "$origName" y "$destName".',
        );
      }
    }

    // 2. Compute in-degree and out-degree for each node
    final inDegree = <String, int>{for (final id in grafo.nodos.keys) id: 0};
    final outDegree = <String, int>{for (final id in grafo.nodos.keys) id: 0};

    for (final conexion in grafo.conexiones.values) {
      if (conexion.direccion == Direccion.unidireccional) {
        outDegree[conexion.nodoOrigenId] = (outDegree[conexion.nodoOrigenId] ?? 0) + 1;
        inDegree[conexion.nodoDestinoId] = (inDegree[conexion.nodoDestinoId] ?? 0) + 1;
      }
    }

    final origins = <Nodo>[];
    final destinations = <Nodo>[];

    // 3. Classify nodes
    for (final node in grafo.nodos.values) {
      final inD = inDegree[node.id] ?? 0;
      final outD = outDegree[node.id] ?? 0;
      final nodeName = node.nombre ?? node.id;

      if (inD == 0 && outD > 0) {
        origins.add(node);
      } else if (outD == 0 && inD > 0) {
        destinations.add(node);
      } else if (inD == 0 && outD == 0) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique el nodo aislado "$nodeName" conectándolo a la red.',
        );
      } else {
        // Node has both in > 0 and out > 0 (Intermediate / Transshipment node)
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique el nodo intermedio "$nodeName" (debe ser únicamente Origen o Destino).',
        );
      }
    }

    if (origins.isEmpty) {
      return const TransportationValidationResult(
        isValid: false,
        errorMessage:
            'No se puede aplicar el algoritmo, modifique el grafo para incluir al menos un nodo de Origen (sin conexiones entrantes).',
      );
    }

    if (destinations.isEmpty) {
      return const TransportationValidationResult(
        isValid: false,
        errorMessage:
            'No se puede aplicar el algoritmo, modifique el grafo para incluir al menos un nodo de Destino (sin conexiones salientes).',
      );
    }

    final originIds = origins.map((n) => n.id).toSet();
    final destIds = destinations.map((n) => n.id).toSet();

    // 4. Verify no origin-to-origin or destination-to-destination connections
    for (final conexion in grafo.conexiones.values) {
      final origName = grafo.nodos[conexion.nodoOrigenId]?.nombre ?? conexion.nodoOrigenId;
      final destName = grafo.nodos[conexion.nodoDestinoId]?.nombre ?? conexion.nodoDestinoId;

      if (originIds.contains(conexion.nodoOrigenId) && originIds.contains(conexion.nodoDestinoId)) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique la conexión entre los orígenes "$origName" y "$destName".',
        );
      }

      if (destIds.contains(conexion.nodoOrigenId) && destIds.contains(conexion.nodoDestinoId)) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique la conexión entre los destinos "$origName" y "$destName".',
        );
      }

      // Check for reverse destination -> origin edge
      if (destIds.contains(conexion.nodoOrigenId) && originIds.contains(conexion.nodoDestinoId)) {
        return TransportationValidationResult(
          isValid: false,
          errorMessage:
              'No se puede aplicar el algoritmo, modifique la conexión inversa de destino a origen entre "$origName" y "$destName".',
        );
      }
    }

    return TransportationValidationResult(
      isValid: true,
      origins: origins,
      destinations: destinations,
    );
  }
}
