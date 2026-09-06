# Editor de Nodos y Grafos (Nodos)

Aplicación interactiva desarrollada en **Flutter** y **Riverpod** para la creación, visualización y edición avanzada de grafos (nodos y conexiones) con soporte para curvas Bézier 2D bidireccionales, personalización de colores, atributos dinámicos y validación de conectividad.

---

## 🌟 Características Principales

- **Gestión de Nodos y Conexiones:**
  - Creación de nodos (cápsulas/círculos) con etiquetas personalizadas y paleta de colores HSL/Neumorphism.
  - Modos de interacción claros: **Añadir**, **Modificar** y **Eliminar**.
  - Soporte para conexiones **sin dirección**, **unidireccionales** y **bidireccionales**.
  - **Manipulación de Curvas 2D:** Ajuste individual e independiente de la curvatura/puntos de control Bézier para cada línea de una conexión bidireccional.
  - **Bucle (Self-loops):** Conexiones de un nodo a sí mismo con rotación orbital de 360°.

- **Diseño UI / UX Neumórfico y M3:**
  - Sistema de temas Neumórficos (modo claro y oscuro) con paleta `NeumorphicPalette`.
  - Configuración global en pantalla completa (`ConfigScreen`) para evitar recortes de texto y mantener espaciados óptimos.
  - Controles flotantes inferiores en fila única horizontal para evitar solapamientos entre la instrucción de modo y las acciones FAB.
  - Diálogos descriptivos confirmando el nombre explícito del nodo a eliminar (ej. *"¿Está seguro de que desea eliminar el nodo [Nombre]?"*).

- **Validación de Grafos en Tiempo Real:**
  - Detección automática de nodos desconectados.
  - Borde rojo persistente (2.5px) alrededor de nodos desconectados que se mantiene visible incluso tras editar el color de relleno del nodo, desapareciendo únicamente al conectarse a otro nodo.
  - Banner informativo en la barra superior con formato descriptivo: `"Grafo inválido. Conecte el (nodo A), (nodo B)"`.

- **Control de Lienzo Avanzado:**
  - Inicialización automática en el máximo nivel de zoom (Zoom Max In).
  - Gestos táctiles separados: 2 dedos para zoom/escalado centrado y 3 dedos para desplazamiento (pan).
  - Botones FAB laterales flotantes (Zoom In, Zoom Out, Centrar) con posición estática fija (`bottom: 84.0`) para evitar saltos de interfaz al abrir/cerrar el panel de edición.

- **Historial e Deshacer/Rehacer (Undo/Redo):**
  - Control completo de estados anteriores para deshacer/rehacer cualquier adición, modificación o eliminación.

---

## 🏗️ Arquitectura del Proyecto

El proyecto sigue **Clean Architecture** estructurada en 3 capas desacopladas:

```text
lib/
├── application/         # Gestión de estado (Riverpod providers & notifiers)
│   ├── providers/       # GrafoNotifier, ModoActivo, Config, Validación, etc.
│   └── state/           # Clases inmutables de estado
├── domain/              # Lógica de dominio pura sin dependencias de Flutter
│   ├── models/          # Nodo, Conexion, Grafo, Direccion, Atributo
│   └── services/        # GraphGeometry, GraphValidation
└── ui/                  # Presentación y widgets Flutter
    ├── canvas/          # GraphCanvas, GraphPainter, GraphHitTester
    ├── dialogs/         # ConfigScreen, DeleteConfirmationDialog, ConnectionDirectionDialog
    ├── theme/           # AppTheme, NeumorphicPalette
    └── widgets/         # EditPanel, HistoryControlsBar, InvalidGraphBanner, BottomMenuBar
```

---

## 🛠️ Ejecución y Pruebas

### Prerrequisitos
- **Flutter SDK** >= 3.0.0
- **Dart SDK** >= 3.0.0

### Instalación
```bash
flutter pub get
```

### Ejecutar Aplicación
```bash
flutter run
```

### Análisis Estático
```bash
flutter analyze
```

### Ejecución de Pruebas Unitarias y de Widget
```bash
flutter test
```

Actualmente, la suite consta de **29 pruebas automatizadas** que cubren:
- Geometría de curvas Bézier y distribución de 12 puntos de conexión por perímetro.
- Algoritmo de resolución de colisiones y separación entre nodos.
- Detección de conectividad de grafos.
- Independencia de curvas 2D en pares bidireccionales.
- Gestión de gestos y límites de zoom/pan en el lienzo.
