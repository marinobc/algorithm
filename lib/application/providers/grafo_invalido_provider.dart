import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/graph_validation.dart';
import 'grafo_provider.dart';

/// Exposes the set of disconnected node IDs if the graph is invalid.
final nodosDesconectadosProvider = Provider<Set<String>>((ref) {
  final grafo = ref.watch(grafoProvider);
  return GraphValidation.findDisconnectedNodes(grafo);
});

/// Evaluates whether the graph is currently in an invalid (disconnected) state.
final esGrafoInvalidoProvider = Provider<bool>((ref) {
  final desconectados = ref.watch(nodosDesconectadosProvider);
  return desconectados.isNotEmpty;
});
