class UserGuideText {
  static const String markdownContent = '''
# Guía de Uso: Editor de Grafos Directo

Bienvenido al **Editor de Grafos Directo**. Esta aplicación permite diseñar, manipular y analizar grafos directamente sobre el lienzo sin necesidad de cambiar manualmente de modo.

---

## 1. Interacción Directa en el Lienzo

- **Tocar una zona libre:** Crea un nuevo nodo en las coordenadas seleccionadas.
- **Arrastrar un nodo:** Presiona y arrastra cualquier nodo para posicionarlo libremente en el espacio 2D.
- **Conectar nodos:** Arrastra desde un nodo de origen y suelta sobre un nodo destino para crear una arista.
- **Seleccionar nodo:** Toca un nodo para abrir su panel de propiedades (nombre, color, eliminación).
- **Seleccionar conexión:** Toca una arista para modificar su dirección, ángulo de bucle, atributos o eliminarla.
- **Bucle (Self-Loop):** Haz doble toque sobre un nodo para crear una conexión dirigida o no dirigida hacia sí mismo.
- **Elementos superpuestos:** Si varios elementos coinciden en una coordenada, un menú flotante permite seleccionar exactamente cuál editar.

---

## 2. Control del Lienzo y Zoom

- **Pellizcar con 2 dedos (Móvil):** Acerca o aleja el zoom del lienzo.
- **Rueda del ratón (Desktop / Web):** Ajusta dinámicamente la escala del espacio de trabajo.
- **Botón Centrar:** Restablece la cámara al origen del lienzo conservando la escala de zoom.

---

## 3. Modelo de Direcciones y Conexiones

- **Modo de Conexión Predeterminado:** Configurable en los ajustes del sistema (Dirigida o No Dirigida).
- **Comportamiento Bidireccional:** Conectar dos nodos en ambos sentidos genera un par bidireccional paralelo con controles independientes.
- **Ángulo de Bucle:** Las conexiones hacia el mismo nodo cuentan con un control deslizante de ángulo para orientar la curva alrededor del nodo.

---

## 4. Validación del Grafo y Matriz de Adyacencia

- **Requisito de Conectividad:** La matriz de adyacencia ponderada sólo puede visualizarse cuando todos los nodos del grafo forman un componente conexo.
- **Notificación de Grafo Desconectado:** Si existen nodos o secciones aisladas, el sistema indicará: *Conecta el grafo para poder ver la matriz*.

---

## 5. Historial y Menú Principal

- **Deshacer y Rehacer:** Permite revertir o restaurar cualquier acción (creación, edición, movimiento o borrado).
- **Guardado Local:** Los grafos se almacenan automáticamente en la biblioteca con sus miniaturas adaptativas.
- **Exportación:** Permite generar y guardar imágenes de alta resolución en formato JPG.
- **Asistente Inteligente:** Chat integrado para responder consultas sobre teoría de grafos y estructura del modelo actual.
''';
}
