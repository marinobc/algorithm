# Guía de Uso del Usuario — Editor de Nodos y Grafos

Bienvenido a la Guía Completa de Uso de Nodos. Este documento explica de forma detallada cómo utilizar todas las herramientas, motores de lienzo, matrices interactivas, algoritmos y asistentes integrados en la aplicación.

---

## 1. Modos de Trabajo y Algoritmos

La aplicación ofrece dos entornos de interacción que se ajustan automáticamente según el modo seleccionado desde la barra superior o el menú lateral (Drawer):

### 1.1 Modo Libre (Freehand)

- Permite construir grafos de cualquier topología sin restricciones de estructura.
- Creación abierta de nodos, conexiones unidireccionales, bidireccionales, no dirigidas y auto-bucles (self-loops).
- Acceso directo a la Matriz de Adyacencia General para inspección de grados y conectividad.

### 1.2 Algoritmo de Asignación (Método Húngaro)

- Topología bipartita: separa el lienzo estrictamente en conjuntos de Orígenes y Destinos.
- Selector flotante: dispone de botones rápidos sobre el lienzo [+ Origen | + Destino] para añadir nodos con roles predefinidos.
- Matriz Bipartita de Costos: permite editar directamente los costos cᵢⱼ en la tabla interactiva de orígenes frente a destinos.
- Resaltado óptimo: muestra sobre el lienzo el costo total mínimo Z y resalta con una capa luminosa (glow) las aristas asignadas.

### 1.3 Algoritmo de Johnson (Ruta Crítica / CPM - PERT)

- Topología DAG: valida en tiempo real que el grafo sea un Grafo Acíclico Dirigido (impide ciclos y aristas hacia atrás).
- Parámetros de proyecto: entrada de duraciones por actividad o arista.
- Resultados automáticos: calcula tiempos tempranos (ES, EF), tiempos tardíos (LS, LF) y holguras totales.
- Capa luminosa: ilumina automáticamente los nodos y aristas pertenecientes a la Ruta Crítica.

---

## 2. Gestión e Interacción con Nodos en el Lienzo

- Crear nodo:
  - En Modo Añadir, toca cualquier área vacía del lienzo.
  - En Algoritmo de Asignación, usa el selector flotante para indicar el rol (Origen o Destino).
- Mover nodos: selecciona el Modo Modificar (o arrastra directamente) para reposicionar cualquier nodo.
- Selección de elementos superpuestos (OverlappingElementsDialog): si pulsas en una zona densa donde varios nodos o aristas se solapan, la aplicación abre automáticamente un diálogo de selección para que elijas el elemento exacto.
- Menú contextual flotante (FloatingContextMenu): haz clic secundario o mantén pulsado un nodo para acceder a acciones rápidas (eliminar, cambiar rol, editar o duplicar).

---

## 3. Gestión y Tipos de Conexiones (Aristas)

Para conectar dos nodos, activa el Modo Añadir, toca el nodo inicial y luego el nodo destino.

### 3.1 Tipos de Dirección

1. Sin dirección (—): arista no dirigida simple.
2. Unidireccional (→): apunta en un único sentido (A → B).
3. Bidireccional (⇄): dos aristas independientes en ambos sentidos (A → B y B → A), cada una con su propia curvatura Bézier y valores.
4. Auto-conexión / Bucle orbital (↻): conexión de 360° que sale y regresa al mismo nodo.

### 3.2 Curvaturas y Edición de Aristas

- Ajuste de curva 2D: en Modo Modificar, toca y arrastra el centro de cualquier línea para ajustar visualmente su curvatura sin alterar las aristas opuestas.
- Entrada de valores numéricos: al crear o pulsar una arista, se abre el diálogo de entrada para definir su costo, peso, capacidad o duración.

---

## 4. Suite de Edición Matricial Interactiva (MatrixViewCoordinator)

Al pulsar el botón de Matriz en la barra superior o menú lateral, el Coordinador Matricial abre la vista correspondiente al algoritmo activo:

### 4.1 Barra de Dimensiones Dinámicas (MatrixDimensionBar)

- Configuración inicial: permite ingresar dimensiones personalizadas (Filas × Columnas) y presionar "Crear Matriz".
- Ajuste en caliente (+ / -): en matrices activas, permite añadir o quitar filas y columnas al final de la tabla en tiempo real sin borrar los valores ya ingresados.

### 4.2 Celdas de Entrada Interactivas (MatrixCellInput)

- Validación en tiempo real: las entradas de texto validan números válidos. Si se ingresa un valor negativo o inválido, la celda se resalta inmediatamente con bordes rojos de advertencia.
- Selección rápida: al hacer clic sobre cualquier celda con valor, el texto se selecciona automáticamente para facilitar su reemplazo.
- Resaltado contextual: las celdas de rutas óptimas, asignaciones activas o cabeceras se destacan con colores del tema.

---

## 5. Panel de Edición Inferior (EditPanel) y Tarjetas Flotantes

- Panel de edición (EditPanel): aparece al seleccionar cualquier nodo o arista. Permite modificar nombres, paleta de colores, curvatura y controles específicos inyectados por el algoritmo activo.
- Tarjetas flotantes de algoritmo (BaseAlgorithmCard): muestran el resumen de resultados flotando sobre el lienzo. Cuentan con botón de minimizar/expandir y cerrar, además de banners contextuales con los valores óptimos calculados.

---

## 6. Gestos y Navegación en el Lienzo

- Moverse por el lienzo: arrastra con 3 dedos o usa clic secundario/panorámica con mouse.
- Acercar y alejar (Zoom): gestos de pellizcar con 2 dedos o rueda del mouse.
- Botones flotantes de control (FABs):
  - Zoom In: incrementa el acercamiento.
  - Zoom Out: disminuye el acercamiento.
  - Centrar: reajusta automáticamente el lienzo para enfocar todos los nodos.
  - Guía / Tutorial: abre esta guía de ayuda.

---

## 7. Historial de Cambios (Undo / Redo)

- Deshacer: revierte la última acción (creación, borrado, movimiento o edición de datos).
- Rehacer: restaura la acción revertida.

---

## 8. Asistente IA, Shell Educativo y Gestión de Proyectos

- Asistente de IA (AIChatDialog): abre el chat de IA en la esquina superior para hacer preguntas teóricas de grafos o solicitar ayuda para construir o resolver un problema.
- Plataforma web educativa: explora los módulos teóricos (¿Qué son los Grafos?, teoría de asignación y ruta crítica) con ejemplos paso a paso y lanzador directo al editor.
- Gestión de archivos: guarda tus grafos localmente, carga proyectos guardados, cambia el nombre del proyecto o exporta la vista del lienzo directamente a imagen JPG.