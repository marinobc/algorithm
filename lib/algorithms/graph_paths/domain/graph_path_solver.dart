import '../../../domain/models/conexion.dart';
import '../../../domain/models/direccion.dart';
import '../../../domain/models/grafo.dart';

/// A calculation error that can be shown to the student without changing the graph.
class GraphPathInputError implements Exception {
  final String message;
  const GraphPathInputError(this.message);

  @override
  String toString() => message;
}

class WeightedEdge {
  final String id;
  final String from;
  final String to;
  final double weight;
  final Direccion direction;

  const WeightedEdge(this.id, this.from, this.to, this.weight, this.direction);
}

class GraphAlgorithmStep {
  final String title;
  final String explanation;
  final String? currentNodeId;
  final String? currentEdgeId;
  final Set<String> highlightedNodes;
  final Set<String> highlightedEdges;
  final Set<String> settledNodes;
  final Set<String> acceptedEdges;
  final Set<String> rejectedEdges;
  final Map<String, double> distances;
  final Map<String, String?> predecessors;
  final Map<String, String> components;
  final double accumulatedWeight;
  final int examinedEdges;
  final int comparisons;

  GraphAlgorithmStep({
    required this.title,
    required this.explanation,
    this.currentNodeId,
    this.currentEdgeId,
    Set<String> highlightedNodes = const {},
    Set<String> highlightedEdges = const {},
    Set<String> settledNodes = const {},
    Set<String> acceptedEdges = const {},
    Set<String> rejectedEdges = const {},
    Map<String, double> distances = const {},
    Map<String, String?> predecessors = const {},
    Map<String, String> components = const {},
    this.accumulatedWeight = 0,
    this.examinedEdges = 0,
    this.comparisons = 0,
  }) : highlightedNodes = Set.unmodifiable(highlightedNodes),
       highlightedEdges = Set.unmodifiable(highlightedEdges),
       settledNodes = Set.unmodifiable(settledNodes),
       acceptedEdges = Set.unmodifiable(acceptedEdges),
       rejectedEdges = Set.unmodifiable(rejectedEdges),
       distances = Map.unmodifiable(distances),
       predecessors = Map.unmodifiable(predecessors),
       components = Map.unmodifiable(components);
}

class GraphPathAlternative {
  final List<String> nodeIds;
  final List<String> edgeIds;
  const GraphPathAlternative(this.nodeIds, this.edgeIds);
}

class GraphComputation {
  final String method;
  final String summary;
  final List<GraphAlgorithmStep> steps;
  final double? value;
  final List<String> pathNodeIds;
  final List<String> pathEdgeIds;
  final List<GraphPathAlternative> alternatives;
  final bool alternativesTruncated;
  final bool exact;
  final List<String> orderedEdgeIds;
  final List<String> acceptedEdgeIds;
  final int componentCount;

  const GraphComputation({
    required this.method,
    required this.summary,
    required this.steps,
    this.value,
    this.pathNodeIds = const [],
    this.pathEdgeIds = const [],
    this.alternatives = const [],
    this.alternativesTruncated = false,
    this.exact = true,
    this.orderedEdgeIds = const [],
    this.acceptedEdgeIds = const [],
    this.componentCount = 0,
  });
}

class _Arc {
  final String to;
  final String edgeId;
  final double weight;
  const _Arc(this.to, this.edgeId, this.weight);
}

class _ParsedGraph {
  final Grafo graph;
  final List<WeightedEdge> edges;
  final List<String> nodeIds;
  final Map<String, List<_Arc>> outgoing;

  _ParsedGraph(this.graph, this.edges)
    : nodeIds = graph.nodos.keys.toList()
        ..sort((a, b) => _nodeName(graph, a).compareTo(_nodeName(graph, b))),
      outgoing = {for (final id in graph.nodos.keys) id: <_Arc>[]} {
    for (final edge in edges) {
      outgoing[edge.from]!.add(_Arc(edge.to, edge.id, edge.weight));
      if (edge.direction != Direccion.unidireccional && edge.from != edge.to) {
        outgoing[edge.to]!.add(_Arc(edge.from, edge.id, edge.weight));
      }
    }
    for (final arcs in outgoing.values) {
      arcs.sort((a, b) {
        final byNode = _nodeName(graph, a.to).compareTo(_nodeName(graph, b.to));
        return byNode != 0 ? byNode : a.edgeId.compareTo(b.edgeId);
      });
    }
  }
}

String _nodeName(Grafo graph, String id) => graph.nodos[id]?.nombre ?? id;

String _format(double value) {
  if (!value.isFinite) return value.isNegative ? '−∞' : '∞';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

bool _equal(double a, double b) => a == b;

/// Pure solvers. The only graph input is the existing Grafo model.
class GraphPathSolver {
  const GraphPathSolver._();

  static _ParsedGraph _parse(Grafo graph) {
    if (graph.nodos.isEmpty) {
      throw const GraphPathInputError('Agrega al menos un vértice al grafo.');
    }
    final edges = <WeightedEdge>[];
    for (final connection in graph.conexiones.values) {
      if (!graph.nodos.containsKey(connection.nodoOrigenId) ||
          !graph.nodos.containsKey(connection.nodoDestinoId)) {
        throw GraphPathInputError(
          'La arista ${connection.id} referencia un vértice inexistente.',
        );
      }
      final values = connection.atributos
          .where((attribute) => attribute.atributoId == 'attr_valor')
          .toList();
      if (values.length != 1 || values.single.valor.trim().isEmpty) {
        throw GraphPathInputError(
          'La arista ${_edgeName(graph, connection)} necesita un peso numérico.',
        );
      }
      final weight = double.tryParse(values.single.valor.trim());
      if (weight == null || !weight.isFinite) {
        throw GraphPathInputError(
          'El peso de ${_edgeName(graph, connection)} debe ser un número finito.',
        );
      }
      edges.add(
        WeightedEdge(
          connection.id,
          connection.nodoOrigenId,
          connection.nodoDestinoId,
          weight,
          connection.direccion,
        ),
      );
    }
    return _ParsedGraph(graph, edges);
  }

  static String _edgeName(Grafo graph, Conexion edge) =>
      '${_nodeName(graph, edge.nodoOrigenId)}–${_nodeName(graph, edge.nodoDestinoId)}';

  static void _checkEndpoints(
    _ParsedGraph input,
    String source,
    String target,
  ) {
    if (!input.graph.nodos.containsKey(source) ||
        !input.graph.nodos.containsKey(target)) {
      throw const GraphPathInputError(
        'Selecciona un origen y un destino existentes.',
      );
    }
  }

  static GraphComputation dijkstra(Grafo graph, String source, String target) {
    final input = _parse(graph);
    _checkEndpoints(input, source, target);
    final negative = input.edges.where((edge) => edge.weight < 0).toList();
    if (negative.isNotEmpty) {
      final edge = graph.conexiones[negative.first.id]!;
      throw GraphPathInputError(
        'Dijkstra clásico no admite pesos negativos. Corrige el peso de ${_edgeName(graph, edge)} o usa otro método.',
      );
    }

    final distances = <String, double>{
      for (final id in input.nodeIds) id: double.infinity,
    }..[source] = 0;
    final predecessors = <String, String?>{
      for (final id in input.nodeIds) id: null,
    };
    final predecessorEdges = <String, String>{};
    final settled = <String>{};
    final steps = <GraphAlgorithmStep>[];
    var examined = 0;
    var comparisons = 0;

    void record(
      String title,
      String explanation, {
      String? node,
      String? edge,
      Set<String> highlightNodes = const {},
      Set<String> highlightEdges = const {},
    }) {
      steps.add(
        GraphAlgorithmStep(
          title: title,
          explanation: explanation,
          currentNodeId: node,
          currentEdgeId: edge,
          highlightedNodes: highlightNodes,
          highlightedEdges: highlightEdges,
          settledNodes: settled,
          distances: distances,
          predecessors: predecessors,
          examinedEdges: examined,
          comparisons: comparisons,
        ),
      );
    }

    record(
      'Inicializar distancias',
      '${_nodeName(graph, source)} recibe 0; los demás vértices reciben ∞.',
      node: source,
      highlightNodes: {source},
    );

    while (true) {
      String? current;
      for (final id in input.nodeIds) {
        if (settled.contains(id) || !distances[id]!.isFinite) continue;
        if (current != null) {
          comparisons++;
          if (distances[id]! >= distances[current]!) continue;
        }
        current = id;
      }
      if (current == null) break;
      final u = current;
      settled.add(u);
      record(
        'Fijar ${_nodeName(graph, u)}',
        '${_nodeName(graph, u)} tiene la menor distancia provisional (${_format(distances[u]!)}). Su distancia ya es definitiva.',
        node: u,
        highlightNodes: {u},
      );

      for (final arc in input.outgoing[u]!) {
        examined++;
        final candidate = distances[u]! + arc.weight;
        final previous = distances[arc.to]!;
        final fromName = _nodeName(graph, u);
        final toName = _nodeName(graph, arc.to);
        record(
          'Examinar $fromName → $toName',
          '${_format(distances[u]!)} + ${_format(arc.weight)} = ${_format(candidate)}; distancia actual de $toName: ${_format(previous)}.',
          node: u,
          edge: arc.edgeId,
          highlightNodes: {u, arc.to},
          highlightEdges: {arc.edgeId},
        );
        comparisons++;
        if (!settled.contains(arc.to) && candidate < previous) {
          distances[arc.to] = candidate;
          predecessors[arc.to] = u;
          predecessorEdges[arc.to] = arc.edgeId;
          record(
            'Actualizar $toName',
            '$toName mejora de ${_format(previous)} a ${_format(candidate)}; su predecesor pasa a ser $fromName.',
            node: arc.to,
            edge: arc.edgeId,
            highlightNodes: {u, arc.to},
            highlightEdges: {arc.edgeId},
          );
        } else {
          record(
            _equal(candidate, previous)
                ? 'Empate en $toName'
                : 'Sin mejora en $toName',
            _equal(candidate, previous)
                ? 'El costo ${_format(candidate)} empata la distancia de $toName. Se conserva el predecesor principal y se registran rutas alternativas al finalizar.'
                : 'El costo ${_format(candidate)} no reduce la distancia de $toName.',
            node: arc.to,
            edge: arc.edgeId,
            highlightNodes: {u, arc.to},
            highlightEdges: {arc.edgeId},
          );
        }
      }
    }

    if (!distances[target]!.isFinite) {
      record(
        'Destino inalcanzable',
        'No existe un camino de ${_nodeName(graph, source)} a ${_nodeName(graph, target)} respetando las direcciones.',
        node: target,
      );
      return GraphComputation(
        method: 'Dijkstra · selección directa O(V² + E)',
        summary: 'No existe ruta al destino.',
        steps: steps,
      );
    }

    final pathNodes = <String>[target];
    final pathEdges = <String>[];
    var cursor = target;
    while (cursor != source) {
      final parent = predecessors[cursor];
      final edge = predecessorEdges[cursor];
      if (parent == null || edge == null) {
        throw const GraphPathInputError(
          'No se pudo reconstruir el camino calculado.',
        );
      }
      pathEdges.insert(0, edge);
      pathNodes.insert(0, parent);
      cursor = parent;
    }

    final alternatives = <GraphPathAlternative>[];
    var explored = 0;
    var truncated = false;
    final visited = <String>{source};
    final walkNodes = <String>[source];
    final walkEdges = <String>[];

    void enumerate(String u) {
      if (alternatives.length >= 9 || explored >= 20000) {
        truncated = true;
        return;
      }
      if (u == target) {
        alternatives.add(
          GraphPathAlternative(List.of(walkNodes), List.of(walkEdges)),
        );
        return;
      }
      for (final arc in input.outgoing[u]!) {
        if (visited.contains(arc.to) ||
            !_equal(distances[u]! + arc.weight, distances[arc.to]!)) {
          continue;
        }
        explored++;
        visited.add(arc.to);
        walkNodes.add(arc.to);
        walkEdges.add(arc.edgeId);
        enumerate(arc.to);
        walkEdges.removeLast();
        walkNodes.removeLast();
        visited.remove(arc.to);
        if (truncated) break;
      }
    }

    enumerate(source);
    final visibleAlternatives = alternatives.take(8).toList();
    if (alternatives.length > 8) truncated = true;
    record(
      'Camino mínimo demostrado',
      '${pathNodes.map((id) => _nodeName(graph, id)).join(' → ')} cuesta ${_format(distances[target]!)}.',
      node: target,
      highlightNodes: pathNodes.toSet(),
      highlightEdges: pathEdges.toSet(),
    );
    return GraphComputation(
      method: 'Dijkstra · selección directa O(V² + E)',
      summary: 'Costo mínimo: ${_format(distances[target]!)}',
      steps: steps,
      value: distances[target],
      pathNodeIds: pathNodes,
      pathEdgeIds: pathEdges,
      alternatives: visibleAlternatives,
      alternativesTruncated: truncated,
    );
  }

  static GraphComputation longestSimplePath(
    Grafo graph,
    String source,
    String target,
  ) {
    final input = _parse(graph);
    _checkEndpoints(input, source, target);
    final topological = _topologicalOrder(input);
    if (topological != null) {
      return _longestDag(input, source, target, topological);
    }
    return _longestGeneral(input, source, target);
  }

  static List<String>? _topologicalOrder(_ParsedGraph input) {
    if (input.edges.any((edge) => edge.direction != Direccion.unidireccional)) {
      return null;
    }
    final incoming = <String, int>{for (final id in input.nodeIds) id: 0};
    for (final edge in input.edges) {
      incoming[edge.to] = incoming[edge.to]! + 1;
    }
    final ready = input.nodeIds.where((id) => incoming[id] == 0).toList();
    final order = <String>[];
    while (ready.isNotEmpty) {
      ready.sort(
        (a, b) =>
            _nodeName(input.graph, a).compareTo(_nodeName(input.graph, b)),
      );
      final u = ready.removeAt(0);
      order.add(u);
      for (final arc in input.outgoing[u]!) {
        incoming[arc.to] = incoming[arc.to]! - 1;
        if (incoming[arc.to] == 0) ready.add(arc.to);
      }
    }
    return order.length == input.nodeIds.length ? order : null;
  }

  static GraphComputation _longestDag(
    _ParsedGraph input,
    String source,
    String target,
    List<String> order,
  ) {
    final graph = input.graph;
    final values = <String, double>{
      for (final id in input.nodeIds) id: double.negativeInfinity,
    }..[source] = 0;
    final previous = <String, String?>{
      for (final id in input.nodeIds) id: null,
    };
    final previousEdges = <String, String>{};
    final steps = <GraphAlgorithmStep>[];
    var examined = 0;
    void record(
      String title,
      String explanation, {
      String? node,
      String? edge,
      Set<String> nodes = const {},
      Set<String> edges = const {},
    }) {
      steps.add(
        GraphAlgorithmStep(
          title: title,
          explanation: explanation,
          currentNodeId: node,
          currentEdgeId: edge,
          highlightedNodes: nodes,
          highlightedEdges: edges,
          distances: values,
          predecessors: previous,
          examinedEdges: examined,
        ),
      );
    }

    record(
      'Orden topológico',
      'El grafo es dirigido y acíclico. Se procesan los nodos en orden topológico: ${order.map((id) => _nodeName(graph, id)).join(' → ')}.',
      node: source,
      nodes: {source},
    );
    for (final u in order) {
      if (!values[u]!.isFinite) continue;
      record(
        'Procesar ${_nodeName(graph, u)}',
        'Mejor costo conocido hasta ${_nodeName(graph, u)}: ${_format(values[u]!)}.',
        node: u,
        nodes: {u},
      );
      for (final arc in input.outgoing[u]!) {
        examined++;
        final candidate = values[u]! + arc.weight;
        record(
          'Evaluar ${_nodeName(graph, u)} → ${_nodeName(graph, arc.to)}',
          '${_format(values[u]!)} + ${_format(arc.weight)} = ${_format(candidate)}; mejor previo: ${_format(values[arc.to]!)}.',
          node: u,
          edge: arc.edgeId,
          nodes: {u, arc.to},
          edges: {arc.edgeId},
        );
        if (candidate > values[arc.to]!) {
          values[arc.to] = candidate;
          previous[arc.to] = u;
          previousEdges[arc.to] = arc.edgeId;
          record(
            'Mejora en ${_nodeName(graph, arc.to)}',
            'Nuevo mejor costo: ${_format(candidate)}; predecesor ${_nodeName(graph, u)}.',
            node: arc.to,
            edge: arc.edgeId,
            nodes: {u, arc.to},
            edges: {arc.edgeId},
          );
        } else {
          record(
            'Sin mejora',
            'La rama no supera el mejor costo de ${_nodeName(graph, arc.to)}.',
            node: arc.to,
            edge: arc.edgeId,
            nodes: {u, arc.to},
            edges: {arc.edgeId},
          );
        }
      }
    }
    if (!values[target]!.isFinite) {
      record(
        'Destino inalcanzable',
        'No existe camino de ${_nodeName(graph, source)} a ${_nodeName(graph, target)}.',
        node: target,
      );
      return GraphComputation(
        method: 'Camino máximo simple · DAG, O(V + E)',
        summary: 'No existe ruta al destino.',
        steps: steps,
      );
    }
    final pathNodes = <String>[target];
    final pathEdges = <String>[];
    var cursor = target;
    while (cursor != source) {
      final parent = previous[cursor]!;
      pathNodes.insert(0, parent);
      pathEdges.insert(0, previousEdges[cursor]!);
      cursor = parent;
    }
    record(
      'Máximo demostrado',
      '${pathNodes.map((id) => _nodeName(graph, id)).join(' → ')} tiene costo ${_format(values[target]!)}.',
      node: target,
      nodes: pathNodes.toSet(),
      edges: pathEdges.toSet(),
    );
    return GraphComputation(
      method: 'Camino máximo simple · DAG, O(V + E)',
      summary: 'Costo máximo simple: ${_format(values[target]!)}',
      steps: steps,
      value: values[target],
      pathNodeIds: pathNodes,
      pathEdgeIds: pathEdges,
    );
  }

  static GraphComputation _longestGeneral(
    _ParsedGraph input,
    String source,
    String target,
  ) {
    final graph = input.graph;
    const method = 'Camino máximo simple · DFS exacto con retroceso';
    if (input.nodeIds.length > 11) {
      return GraphComputation(
        method: method,
        summary: 'Búsqueda incompleta: el límite seguro es 11 vértices. No se ha demostrado un máximo.',
        exact: false,
        steps: [
          GraphAlgorithmStep(
            title: 'Límite de trabajo',
            explanation: 'Para evitar bloquear Flutter Web, el DFS exacto se limita a 11 vértices. Reduce el grafo o usa un DAG dirigido.',
          ),
        ],
      );
    }
    final steps = <GraphAlgorithmStep>[];
    final visited = <String>{source};
    final currentNodes = <String>[source];
    final currentEdges = <String>[];
    var best = double.negativeInfinity;
    var bestNodes = <String>[];
    var bestEdges = <String>[];
    var expansions = 0;
    var incomplete = false;

    void record(
      String title,
      String explanation, {
      String? node,
      String? edge,
    }) {
      steps.add(
        GraphAlgorithmStep(
          title: title,
          explanation: explanation,
          currentNodeId: node,
          currentEdgeId: edge,
          highlightedNodes: currentNodes.toSet(),
          highlightedEdges: currentEdges.toSet(),
          examinedEdges: expansions,
        ),
      );
    }

    record(
      'Iniciar DFS',
      'Se buscan caminos simples de ${_nodeName(graph, source)} a ${_nodeName(graph, target)}. Ningún vértice puede repetirse.',
      node: source,
    );
    void dfs(String u, double cost) {
      if (u == target) {
        if (cost > best) {
          best = cost;
          bestNodes = List.of(currentNodes);
          bestEdges = List.of(currentEdges);
          record(
            'Mejor camino conocido',
            'El camino actual cuesta ${_format(cost)} y supera al mejor anterior.',
            node: u,
          );
        } else {
          record(
            'Evaluar alternativa',
            'El camino actual cuesta ${_format(cost)} y no mejora el máximo conocido.',
            node: u,
          );
        }
        return;
      }
      for (final arc in input.outgoing[u]!) {
        if (visited.contains(arc.to)) continue;
        if (expansions >= 5000) {
          incomplete = true;
          return;
        }
        expansions++;
        visited.add(arc.to);
        currentNodes.add(arc.to);
        currentEdges.add(arc.edgeId);
        record(
          'Explorar ${_nodeName(graph, u)} → ${_nodeName(graph, arc.to)}',
          'Costo acumulado: ${_format(cost)} + ${_format(arc.weight)} = ${_format(cost + arc.weight)}. Visitados: ${currentNodes.map((id) => _nodeName(graph, id)).join(', ')}.',
          node: arc.to,
          edge: arc.edgeId,
        );
        dfs(arc.to, cost + arc.weight);
        currentEdges.removeLast();
        currentNodes.removeLast();
        visited.remove(arc.to);
        record(
          'Retroceder',
          'Se vuelve a ${_nodeName(graph, u)} para explorar otra rama sin repetir vértices.',
          node: u,
          edge: arc.edgeId,
        );
        if (incomplete) return;
      }
    }

    dfs(source, 0);
    if (incomplete) {
      record(
        'Búsqueda incompleta',
        'Se alcanzó el límite de 5000 expansiones. El mejor camino conocido no está demostrado como máximo.',
        node: target,
      );
      return GraphComputation(
        method: method,
        summary: best.isFinite
            ? 'Búsqueda incompleta; mejor costo conocido: ${_format(best)} (no demostrado).'
            : 'Búsqueda incompleta; no se ha demostrado un máximo.',
        steps: steps,
        value: best.isFinite ? best : null,
        pathNodeIds: bestNodes,
        pathEdgeIds: bestEdges,
        exact: false,
      );
    }
    if (!best.isFinite) {
      record(
        'Destino inalcanzable',
        'No existe camino simple al destino.',
        node: target,
      );
      return GraphComputation(
        method: method,
        summary: 'No existe ruta al destino.',
        steps: steps,
      );
    }
    steps.add(
      GraphAlgorithmStep(
        title: 'Máximo demostrado',
        explanation:
            '${bestNodes.map((id) => _nodeName(graph, id)).join(' → ')} cuesta ${_format(best)}; se agotaron todas las rutas simples permitidas.',
        currentNodeId: target,
        highlightedNodes: bestNodes.toSet(),
        highlightedEdges: bestEdges.toSet(),
        examinedEdges: expansions,
      ),
    );
    return GraphComputation(
      method: method,
      summary: 'Costo máximo simple: ${_format(best)}',
      steps: steps,
      value: best,
      pathNodeIds: bestNodes,
      pathEdgeIds: bestEdges,
    );
  }

  static GraphComputation kruskal(Grafo graph, {required bool maximum}) {
    final input = _parse(graph);
    if (input.edges.any((edge) => edge.direction != Direccion.ninguna)) {
      throw const GraphPathInputError(
        'Kruskal necesita aristas no dirigidas. El grafo no se convertirá automáticamente: cambia explícitamente la dirección de las aristas incompatibles.',
      );
    }
    final ordered = List<WeightedEdge>.of(input.edges)
      ..sort((a, b) {
        final byWeight = maximum
            ? b.weight.compareTo(a.weight)
            : a.weight.compareTo(b.weight);
        if (byWeight != 0) return byWeight;
        String key(WeightedEdge e) {
          final names = [_nodeName(graph, e.from), _nodeName(graph, e.to)]
            ..sort();
          return '${names.first}|${names.last}|${e.id}';
        }

        return key(a).compareTo(key(b));
      });
    final parent = <String, String>{for (final id in input.nodeIds) id: id};
    final size = <String, int>{for (final id in input.nodeIds) id: 1};
    String find(String id) {
      if (parent[id] != id) parent[id] = find(parent[id]!);
      return parent[id]!;
    }

    void union(String a, String b) {
      var rootA = find(a);
      var rootB = find(b);
      if (size[rootA]! < size[rootB]!) {
        final tmp = rootA;
        rootA = rootB;
        rootB = tmp;
      }
      parent[rootB] = rootA;
      size[rootA] = size[rootA]! + size[rootB]!;
    }

    Map<String, String> components() {
      final roots = input.nodeIds.map(find).toSet().toList()
        ..sort((a, b) => _nodeName(graph, a).compareTo(_nodeName(graph, b)));
      return {
        for (final id in input.nodeIds) id: 'C${roots.indexOf(find(id)) + 1}',
      };
    }

    final accepted = <String>{};
    final rejected = <String>{};
    final steps = <GraphAlgorithmStep>[];
    var total = 0.0;
    var examined = 0;
    void record(
      String title,
      String explanation, {
      String? edgeId,
      Set<String> nodes = const {},
    }) {
      steps.add(
        GraphAlgorithmStep(
          title: title,
          explanation: explanation,
          currentEdgeId: edgeId,
          highlightedNodes: nodes,
          highlightedEdges: {...accepted, ?edgeId},
          acceptedEdges: accepted,
          rejectedEdges: rejected,
          components: components(),
          accumulatedWeight: total,
          examinedEdges: examined,
        ),
      );
    }

    record(
      'Ordenar aristas',
      'Se ordenan ${ordered.length} aristas por peso ${maximum ? 'descendente' : 'ascendente'}; los empates se resuelven por nombres e ID.',
    );
    for (var i = 0; i < ordered.length; i++) {
      final edge = ordered[i];
      final fromName = _nodeName(graph, edge.from);
      final toName = _nodeName(graph, edge.to);
      examined++;
      record(
        'Examinar ${i + 1}/${ordered.length}: $fromName–$toName',
        'Peso ${_format(edge.weight)}. $fromName está en ${components()[edge.from]} y $toName en ${components()[edge.to]}.',
        edgeId: edge.id,
        nodes: {edge.from, edge.to},
      );
      if (find(edge.from) == find(edge.to)) {
        rejected.add(edge.id);
        record(
          'Rechazar $fromName–$toName',
          edge.from == edge.to
              ? 'Es un bucle: formaría un ciclo en el mismo vértice.'
              : 'Ambos extremos ya están conectados; agregar esta arista formaría un ciclo.',
          edgeId: edge.id,
          nodes: {edge.from, edge.to},
        );
      } else {
        union(edge.from, edge.to);
        accepted.add(edge.id);
        total += edge.weight;
        record(
          'Aceptar $fromName–$toName',
          'Une dos componentes distintas. Peso acumulado: ${_format(total)}.',
          edgeId: edge.id,
          nodes: {edge.from, edge.to},
        );
      }
    }
    final componentCount = input.nodeIds.map(find).toSet().length;
    final noun = componentCount == 1
        ? 'Árbol'
        : 'Bosque de $componentCount componentes';
    record(
      'Resultado ${maximum ? 'máximo' : 'mínimo'}',
      '$noun con ${accepted.length} aristas y peso total ${_format(total)}. ${componentCount > 1 ? 'Se conservan los vértices aislados.' : ''}',
    );
    return GraphComputation(
      method:
          'Kruskal ${maximum ? 'máximo' : 'mínimo'} · Union-Find, O(E log E)',
      summary: '$noun · peso ${_format(total)}',
      steps: steps,
      value: total,
      orderedEdgeIds: ordered.map((e) => e.id).toList(),
      acceptedEdgeIds: accepted.toList(),
      componentCount: componentCount,
    );
  }
}
