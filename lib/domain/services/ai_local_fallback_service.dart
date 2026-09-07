import '../../domain/models/grafo.dart';
import '../../domain/services/adjacency_matrix_service.dart';

/// Helper service responsible for offline, rule-based NLP response generation
/// when GEMINI_API_KEY is absent or unavailable.
class AILocalFallbackService {
  static String generateFallbackResponse(String userPrompt, Grafo graph) {
    final promptLower = userPrompt.toLowerCase();

    final isGraphQuery =
        promptLower.contains('matriz') ||
        promptLower.contains('grado') ||
        promptLower.contains('nodo') ||
        promptLower.contains('conexion') ||
        promptLower.contains('arista') ||
        promptLower.contains('resumen') ||
        promptLower.contains('conect') ||
        promptLower.contains('guia') ||
        promptLower.contains('uso') ||
        promptLower.contains('como') ||
        promptLower.contains('ayuda') ||
        promptLower.contains('hola');

    if (!isGraphQuery) {
      return 'Disculpa, solo puedo responder preguntas relacionadas con el grafo y matriz actuales o sobre cómo utilizar esta aplicación de grafos.\n\n'
          '*(Para consultas generativas avanzadas con IA, agrega tu `GEMINI_API_KEY` en el archivo `.env`)*';
    }

    if (promptLower.contains('matriz') || promptLower.contains('adyacencia')) {
      if (graph.nodos.isEmpty) {
        return 'El grafo está vacío. Agrega nodos al lienzo para ver la matriz.';
      }
      final matrixData = AdjacencyMatrixService.calculateMatrix(graph);
      return '### Matriz de Adyacencia Actual\n'
          '• **Dimensiones:** ${matrixData.labels.length}x${matrixData.labels.length}\n'
          '• **Nodos:** ${matrixData.labels.join(", ")}\n'
          '• **Grado Máximo Δ(G):** ${matrixData.maxDegree}\n'
          '• **Grado Mínimo δ(G):** ${matrixData.minDegree}\n'
          '• **Suma Total de Pesos:** ${matrixData.totalWeightSum.toStringAsFixed(1)}';
    }

    if (promptLower.contains('grado') ||
        promptLower.contains('conexion') ||
        promptLower.contains('vecino')) {
      if (graph.nodos.isEmpty) return 'El grafo está vacío.';
      final matrixData = AdjacencyMatrixService.calculateMatrix(graph);
      final summary = <String>[];
      for (int i = 0; i < matrixData.nodes.length; i++) {
        summary.add(
          '• **${matrixData.labels[i]}:** Grado ${matrixData.vertexDegrees[i]} (Suma filas: ${matrixData.rowSums[i].toStringAsFixed(1)})',
        );
      }
      return '### Grados e Incidentes por Nodo\n'
          '${summary.join("\n")}\n\n'
          '• **Δ(G):** ${matrixData.maxDegree} | **δ(G):** ${matrixData.minDegree}';
    }

    if (promptLower.contains('guia') ||
        promptLower.contains('uso') ||
        promptLower.contains('como')) {
      return '### Resumen de la Guía de Uso\n'
          '1. **Crear Nodo:** Toca una zona libre del lienzo.\n'
          '2. **Mover Nodo:** Mueve arrastrando cualquier nodo.\n'
          '3. **Conectar Nodos:** Arrastra desde un nodo de origen hasta el destino.\n'
          '4. **Bucle:** Doble toque en un nodo.\n'
          '5. **Editar/Borrar:** Toca el nodo o arista para abrir el panel de edición inferior.\n'
          '6. **Ver Matriz:** Accesible desde el menú lateral si todos los nodos están conectados.';
    }

    final n = graph.nodos.length;
    final c = graph.conexiones.length;
    return 'Tu grafo actual contiene **$n nodo(s)** y **$c conexión(es)**.\n\n'
        '¿Deseas consultar el **grado de los nodos**, la **matriz de adyacencia** o ver la **guía de uso**?\n\n'
        '*(Nota: Configura tu `GEMINI_API_KEY` en `.env` para desbloquear búsqueda web e inserción automática de grafos por IA)*';
  }
}
