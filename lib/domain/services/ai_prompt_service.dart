import '../../domain/models/grafo.dart';
import '../../domain/services/adjacency_matrix_service.dart';
import '../../ui/text/user_guide_text.dart';

/// Helper service responsible for formatting graph state and generating
/// system prompts for the AI Assistant.
class AIPromptService {
  /// Builds a structured text snapshot of nodes, connections, and adjacency matrix.
  static String buildGraphContext(Grafo graph) {
    final buffer = StringBuffer();
    buffer.writeln("=== ESTADO DEL GRAFO ACTUAL ===");
    buffer.writeln("Cantidad de Nodos: ${graph.nodos.length}");
    buffer.writeln("Cantidad de Conexiones: ${graph.conexiones.length}");

    if (graph.nodos.isNotEmpty) {
      buffer.writeln("\nNodos:");
      for (final n in graph.nodos.values) {
        buffer.writeln(
          " - ID: ${n.id}, Nombre: '${n.nombre ?? n.id}', Posición: (${n.x.toStringAsFixed(1)}, ${n.y.toStringAsFixed(1)})",
        );
      }

      buffer.writeln("\nConexiones:");
      for (final c in graph.conexiones.values) {
        final orig = graph.nodos[c.nodoOrigenId]?.nombre ?? c.nodoOrigenId;
        final dest = graph.nodos[c.nodoDestinoId]?.nombre ?? c.nodoDestinoId;
        final attrs = c.atributos
            .map((a) => "${a.atributoId}: ${a.valor}")
            .join(", ");
        buffer.writeln(
          " - ID: ${c.id}, Origen: '$orig', Destino: '$dest', Dirección: ${c.direccion.name}, Atributos: [${attrs.isEmpty ? 'Ninguno' : attrs}]",
        );
      }

      final matrixData = AdjacencyMatrixService.calculateMatrix(graph);
      buffer.writeln("\n=== MATRIZ DE ADYACENCIA ===");
      buffer.writeln("Etiquetas de Nodos: ${matrixData.labels.join(', ')}");
      buffer.writeln(
        "Matriz (${matrixData.labels.length}x${matrixData.labels.length}):",
      );
      for (int i = 0; i < matrixData.matrix.length; i++) {
        final rowStr = matrixData.matrix[i]
            .map((cell) => cell.weightedValue)
            .join('\t');
        buffer.writeln(
          " ${matrixData.labels[i]}\t[ $rowStr ]\t| Suma: ${matrixData.rowSums[i].toStringAsFixed(1)}, Grado: ${matrixData.rowDegrees[i]}",
        );
      }
      buffer.writeln("Grado Máximo Δ(G): ${matrixData.maxDegree}");
      buffer.writeln("Grado Mínimo δ(G): ${matrixData.minDegree}");
      buffer.writeln(
        "Suma Total de Pesos: ${matrixData.totalWeightSum.toStringAsFixed(1)}",
      );
    } else {
      buffer.writeln("El lienzo está actualmente vacío.");
    }
    return buffer.toString();
  }

  /// Builds the complete system prompt including graph context, user guide, and JSON action rules.
  static String buildSystemPrompt(Grafo graph) {
    final graphContext = buildGraphContext(graph);
    final guideContext = UserGuideText.markdownContent;

    return '''
Eres el Asistente Experto en Teoría de Grafos, Modificación de Grafos y Manual de Usuario de esta aplicación.

REGLAS DE RESPUESTA STRICTAS:
1. SOLO debes responder a preguntas o solicitudes relacionadas con:
   a) El grafo y la matriz de adyacencia cargados actualmente (nodos, conexiones, grados, pesos, caminos, propiedades topológicas).
   b) El uso y funcionamiento de la aplicación (explicado en la Guía de Uso adjunta).
   c) Creación, adición, modificación o eliminación de nodos y conexiones en el lienzo.

2. SI EL USUARIO HACE UNA PREGUNTA AJENA O NO RELACIONADA con el grafo, la matriz de adyacencia o el uso de la aplicación (por ejemplo: recetas de cocina, fútbol, chistes, política, programación general), DEBES DECLINAR AMABLEMENTE diciendo:
   "Disculpa, solo puedo responder preguntas sobre el grafo actual, la matriz de adyacencia, cómo usar la app o generar/modificar grafos."

3. ACCIONES DE CREACIÓN Y MODIFICACIÓN DE GRAFOS:
   Cuando el usuario solicite crear, agregar, modificar o eliminar nodos o conexiones:
   - Proporciona una explicación clara en tu respuesta textual.
   - AL FINAL DE TU RESPUESTA, DEBES INCLUIR UN ÚNICO BLOQUE DE CÓDIGO JSON ```json ... ``` con una de las siguientes estructuras de acción (sin alterar los nombres de las claves):

   a) CREAR UN GRAFO COMPLETO (reemplaza el lienzo):
```json
{
  "action": "create_graph",
  "graph_name": "Nombre del Grafo",
  "nodes": ["Nodo A", "Nodo B", "Nodo C"],
  "connections": [
    {"from": "Nodo A", "to": "Nodo B", "directed": true, "weight": 1.0},
    {"from": "Nodo B", "to": "Nodo C", "directed": false, "weight": 2.5}
  ]
}
```

   b) AÑADIR N ELEMENTOS AL GRAFO ACTUAL (sin borrar los existentes):
```json
{
  "action": "add_elements",
  "nodes": ["Nuevo Nodo D"],
  "connections": [
    {"from": "Nodo A", "to": "Nuevo Nodo D", "directed": false, "weight": 3.0}
  ]
}
```

   c) ELIMINAR ELEMENTOS DEL LIENZO:
```json
{
  "action": "remove_elements",
  "nodes": ["Nodo B"]
}
```

   d) ACTUALIZAR ELEMENTOS EXISTENTES (nombres, colores o pesos):
```json
{
  "action": "update_elements",
  "connections": [
    {"from": "Nodo A", "to": "Nodo B", "weight": 10.0, "directed": true}
  ]
}
```

=== INFORMACIÓN DEL GRAFO Y MATRIZ ACTUAL ===
$graphContext

=== GUÍA DE USO DE LA APLICACIÓN ===
$guideContext
''';
  }
}
