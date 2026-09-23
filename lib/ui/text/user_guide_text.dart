class UserGuideText {
  static const String markdownContent = '''
# Guía de Uso: Editor de Grafos e Historial Algorítmico

Bienvenido al **Editor de Nodos y Grafos**. Esta aplicación permite diseñar, manipular, simular y analizar grafos directamente sobre el lienzo, además de explorar fundamentos teóricos y resolver algoritmos clásicos de la ciencia de computación y la investigación operacional.

---

## 1. Interacción Directa en el Lienzo

- **Tocar una zona libre:** Crea un nuevo nodo en las coordenadas seleccionadas.
- **Arrastrar un nodo:** Presiona y arrastra cualquier nodo para posicionarlo libremente en el espacio 2D.
- **Conectar nodos:** Arrastra desde un nodo de origen y suelta sobre un nodo destino para crear una arista.
- **Seleccionar nodo:** Toca un nodo para abrir su panel inferior de propiedades (nombre, color, rol, eliminación y controles inyectados por el algoritmo activo).
- **Seleccionar conexión:** Toca una arista para modificar su costo, dirección, curvatura Bézier 2D, atributos o eliminarla.
- **Bucle (Self-Loop):** Haz doble toque sobre un nodo para crear una auto-conexión orbital de 360°.
- **Elementos superpuestos:** Si varios elementos coinciden en una coordenada, el modal inteligente te permite elegir exactamente cuál editar.

---

## 2. Modos de Asignación de Roles de Nodo

Configurable desde la pantalla de **Ajustes**:

- **Tipo Declarado:** Seleccionas explícitamente si el nuevo nodo es `Origen` o `Destino` utilizando la barra de herramientas del lienzo antes de crearlo.
- **Tipo Detectado:** Insertas nodos sin rol previo. La aplicación detecta y asigna reactivamente el rol `Origen` o `Destino` al trazar conexiones.
  - *Posicionamiento de valores:* La oferta/demanda de nodos sin conectar aparece justo **debajo del nodo**. Al conectarse, se desplaza a la izquierda (origen) o derecha (destino).
  - *Reversión automática:* Si eliminas todas las conexiones de un nodo, retorna automáticamente al estado sin rol.

---

## 3. Algoritmos Disponibles y Validaciones en Tiempo Real

- **Modo Libre:** Diseña cualquier estructura de grafos sin restricciones de algoritmo.
- **Algoritmo de Asignación (Húngaro):**
  - Aplica políticas de grafo bipartito (partición entre Origen y Destino).
  - Matriz de costos dedicada con editor interactivo en lote.
  - Resaltado luminoso en tiempo real de asignaciones óptimas.
- **Algoritmo de Johnson (Ruta Crítica / CPM - PERT):**
  - Validación de redes dirigidas acíclicas (DAG) evitando ciclos.
  - Cálculo de tiempos tempranos, tardíos y holguras con trazado de Ruta Crítica sobre el lienzo.
- **Esquina Noroeste (Transporte & MODI):**
  - Resolución de problemas de transporte con auto-balanceo de oferta y demanda mediante filas/columnas ficticias.

---

## 4. Navegación Web Educativa y Catálogo

- **Botón "Dibujar Rápido" en Encabezado:** Toda pantalla de explicación teórica cuenta con un botón en la cabecera hero para saltar directamente al lienzo de dibujo del algoritmo correspondiente.
- **Catálogo Desktop & Móvil:** Selecciona algoritmos en una cuadrícula fluida sin barra de desplazamiento visible, navegable con rueda de ratón o pantalla táctil.

---

## 5. Matrices Interactivas y Coordinador

- **Navegación Polimórfica:** El botón de matriz abre automáticamente la vista matricial del algoritmo activo o la matriz de adyacencia general en modo libre.
- **Edición en Caliente:** Agrega o quita filas y columnas en tiempo real con validación de entradas numéricas en rojo.

---

## 6. Historial, Guardado y Asistente IA

- **Deshacer y Rehacer:** Revierte o restaura cualquier modificación (nodos, aristas, valores o borrado).
- **Biblioteca y Exportación:** Guardado automático local y exportación de imágenes JPG de alta calidad.
- **Asistente IA:** Consulta teórica y ayuda en lenguaje natural integrada en el lienzo.
''';
}
