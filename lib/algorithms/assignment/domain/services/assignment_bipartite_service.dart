import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';

/// Pure Dart domain service for extracting bipartite cost matrix structures
/// and connection attributes from a graph.
class AssignmentBipartiteService {
  const AssignmentBipartiteService._();

  /// Finds and returns the weight/cost value of a directed or undirected connection
  /// between [origId] and [destId] in [grafo].
  static double? getConnectionWeight(
    Grafo grafo,
    String origId,
    String destId,
  ) {
    Conexion? matchingCon;
    for (final c in grafo.conexiones.values) {
      if (c.nodoOrigenId == origId && c.nodoDestinoId == destId) {
        matchingCon = c;
        break;
      }
    }
    if (matchingCon == null) return null;

    final pesoAttr = matchingCon.atributos.firstWhere(
      (a) =>
          a.atributoId == 'attr_valor' ||
          a.atributoId.toLowerCase().contains('cost') ||
          a.atributoId.toLowerCase().contains('peso') ||
          a.atributoId.toLowerCase().contains('valor'),
      orElse: () => matchingCon!.atributos.isNotEmpty
          ? matchingCon.atributos.first
          : const AtributoValor(atributoId: '', valor: '1'),
    );

    final numVal = double.tryParse(pesoAttr.valor);
    return numVal ?? 0.0;
  }

  /// Builds a 2D matrix of cost values between [origins] (rows) and [destinations] (columns).
  static List<List<double?>> buildCostMatrix(
    Grafo grafo,
    List<Nodo> origins,
    List<Nodo> destinations,
  ) {
    return List.generate(
      origins.length,
      (i) => List.generate(
        destinations.length,
        (j) => getConnectionWeight(
          grafo,
          origins[i].id,
          destinations[j].id,
        ),
      ),
    );
  }

  /// Formats a numerical value for display in matrix cells.
  static String formatCellText(double? val) {
    if (val == null) return '-';
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}
