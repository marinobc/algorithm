# Editor de Nodos y Grafos (Nodos)

Aplicación web y móvil interactiva desarrollada en **Flutter** y **Riverpod** para el diseño, simulación, visualización y resolución algorítmica de grafos. Cuenta con soporte para curvas Bézier 2D bidireccionales, políticas de dibujo en tiempo real, matrices interactivas dedicadas, shell web educativo (PWA), y un sistema desacoplado y modular para incorporar nuevos algoritmos de teoría de grafos.

---

## Características Principales

### 1. Motor de Lienzo y Dibujo Avanzado
- **Interacción Multitáctil y Fluida:**
  - Desplazamiento (pan), zoom centrado suave e inicialización automática en zoom óptimo.
  - Botones flotantes (FAB) para control de zoom y centrado de lienzo.
  - Detección precisa de selección (*Hit Testing*) para nodos, aristas curvas y bucles orbitales.
  - Diálogo inteligente para resolución de selección de elementos superpuestos (`OverlappingElementsDialog`).
- **Nodos y Conexiones Personalizables:**
  - Nodos con nombres dinámicos, colores personalizados y roles contextuales.
  - Conexiones no dirigidas, unidireccionales y bidireccionales con curvaturas Bézier 2D independientes por sentido.
  - Auto-conexiones orbitales (*self-loops*) de 360°.
  - Edición de valores numéricos, costos y atributos dinámicos mediante diálogos contextuales.
- **Historial Completo (Undo / Redo):**
  - Deshacer y rehacer cualquier mutación (creación, edición, arrastre o eliminación) con detección de cambios no guardados.

### 2. Arquitectura Modular de Algoritmos (Extensible)
El lienzo se adapta dinámicamente al algoritmo seleccionado a través de contratos desacoplados (**SOLID & SRP**):
- **Modo Libre (Freehand):** Creación libre y sin restricciones de cualquier topología de grafo.
- **Algoritmo de Asignación (Método Húngaro):**
  - Política de grafo bipartito (partición estricta entre nodos Origen y Destino).
  - Selector flotante sobre el lienzo para alternar roles `[+ Origen | + Destino]`.
  - Matriz de costos bipartita dedicada (`AssignmentBipartiteMatrixScreen`) con editor interactivo de valores (`AssignmentMatrixInputDialog`).
  - Iluminación en tiempo real en el lienzo de las aristas y nodos asignados óptimamente.
- **Algoritmo de Johnson (Ruta Crítica / CPM - PERT):**
  - Validación de grafo acíclico dirigido (DAG) en tiempo real (evita ciclos y aristas hacia atrás).
  - Cálculo de tiempos tempranos, tiempos tardíos y holguras.
  - Resaltado automático de la Ruta Crítica sobre el lienzo con capa luminosa (*glow underlay*).

### 3. Matrices Interactivas y Suite de Edición Matricial (`lib/ui/widgets/matrix/`)
- **Coordinador Central (`MatrixViewCoordinator`):** Resuelve dinámicamente la vista matricial correspondiente según el modo activo o deriva a la matriz general en modo libre.
- **Barra de Dimensiones Dinámicas (`MatrixDimensionBar`):** Permite configurar dimensiones iniciales (`Filas × Columnas`) y modificar en caliente añadiendo o quitando filas y columnas mediante controles `+` / `-`.
- **Celdas de Entrada Interactivas (`MatrixCellInput`):** Celdas matriciales modulares con validación en tiempo real, estilos de error en rojo para entradas numéricas inválidas, auto-selección de texto al pulsar y resaltado contextual de celdas.
- **Configuración Declarativa Bipartita (`BipartiteMatrixConfig`):** Contrato para parametrizar matrices de asignación y transporte (filas de origen, columnas de destino, oferta/demanda y balanceo de filas/columnas ficticias).
- **Matriz de Adyacencia General:** Inspección de conexiones, grados de nodos y estado de conectividad en tiempo real.

### 4. Plataforma Web Educativa y PWA
- **Shell de Explicación Responsivo:**
  - Barra de navegación (`WebExplanationNavbar`) y menú lateral drawer para escritorio y móviles.
  - Pantalla explicativa interactiva: *¿Qué son los Grafos?*, fundamentos, aplicaciones reales y conceptos visuales.
  - Páginas dedicadas para cada algoritmo con teoría, ejemplos paso a paso y botón de lanzamiento directo al editor.
  - Instalable como Progressive Web App (PWA) con soporte offline y manifiesto web optimizado.

### 5. Asistente IA y Componentes Modulares
- **Tarjetas Flotantes de Algoritmo (`BaseAlgorithmCard`):** Shell estandarizado para tarjetas de resultados de algoritmos con cabecera, minimizado/expandido y banner de resultados.
- **Chat Asistente con IA (`AIChatDialog`):** Asistencia en lenguaje natural para manipulación guiada de grafos y consultas teóricas.
- **Gestión de Proyectos:** Guardado local, carga de proyectos guardados, renombramiento y exportación directa del grafo a imagen JPG.
- **Retroalimentación Unificada:** Sistema centralizado de notificaciones flotantes tipo píldora (`AppToast`).

---

## Arquitectura del Software

El proyecto implementa los principios de **Clean Architecture**, **SOLID** y programación reactiva con **Riverpod**:

```text
lib/
├── algorithms/                  # Framework y plugins de algoritmos
│   ├── core/                   # Contratos abstractos (GraphAlgorithm, GraphAlgorithmPolicy, AlgorithmRegistry)
│   ├── assignment/             # Algoritmo de Asignación (Húngaro: modelos, solvers, UI y matriz)
│   └── johnson/                # Algoritmo de Johnson (CPM/PERT: modelos, validación DAG y UI)
│
├── application/                # Gestión de estado (Riverpod StateNotifiers / Notifiers)
│   ├── providers/              # grafoProvider, edicionProvider, modoActivoProvider, etc.
│   └── state/                  # Modelos inmutables de estado de aplicación
│
├── domain/                     # Lógica de negocio pura (Dart puro, sin dependencias de Flutter)
│   ├── models/                 # Grafo, Nodo, Conexion, Atributo, Direccion
│   ├── highlights/             # AlgorithmHighlight (contrato visual de resaltado)
│   └── services/               # Geometría, validación de conectividad, exportación
│
├── ui/                         # Capa de presentación y widgets Flutter
│   ├── canvas/                 # GraphCanvas, GraphPainter (renderizado de curvas y glow underlays)
│   ├── dialogs/                # Diálogos modales, MatrixViewCoordinator, configuración, chat IA
│   ├── screens/                # GraphEditorScreen, pantallas explicativas web
│   ├── theme/                  # AppTheme (Neumorphic & Material 3, soporte claro/oscuro)
│   └── widgets/                # AppToast, BaseAlgorithmCard, EditPanel, AppDrawer, CanvasControlsFabs, matrix/
│       └── matrix/             # MatrixDimensionBar, MatrixCellInput, BipartiteMatrixConfig
│
└── main.dart                   # Punto de entrada de la aplicación
```

---

## Instalación y Desarrollo

### Prerrequisitos
- **Flutter SDK**: `>= 3.19.0` (o versión estable reciente)
- **Dart SDK**: `>= 3.3.0`

### 1. Clonar el repositorio
```bash
git clone https://github.com/marinobc/algorithm.git
cd algorithm
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Ejecutar en local
```bash
# Para Web (Chrome)
flutter run -d chrome

# Para Windows Desktop
flutter run -d windows
```

### 4. Análisis de código
```bash
flutter analyze
```

### 5. Suite de Pruebas
Ejecutar la suite completa de pruebas unitarias y de widgets:
```bash
flutter test
```

Las pruebas cubren:
- Geometría de curvas Bézier y puntos de anclaje perimetrales.
- Validación de políticas de algoritmos (restricciones de asignación bipartita y aciclicidad de Johnson).
- Algoritmos matemáticos (Hungarian solver, Johnson topological pass).
- Pruebas de widgets (renderizado del canvas, paneles de edición y matrices modulares).

---

## Cómo Contribuir
Consulta el archivo [`AGENTS.md`](./AGENTS.md) para conocer las pautas de estilo de código, buenas prácticas de desarrollo, manejo de estado con Riverpod y la guía paso a paso para crear un nuevo algoritmo modular.
