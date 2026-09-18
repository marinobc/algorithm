# Guía de Desarrollo y Buenas Prácticas para Agentes y Desarrolladores (AGENTS.md)

Este documento establece las reglas de arquitectura, estándares de código, patrones de diseño y flujos de trabajo para contribuir en el proyecto **Nodos (Editor de Grafos)**. Cualquier desarrollador o agente de IA debe seguir estas pautas rigurosamente.

---

## 1. Principios Fundamentales y Arquitectura

El proyecto está diseñado bajo **Clean Architecture**, **SOLID** (especialmente SRP y OCP) y programación reactiva mediante **Riverpod**:

```
lib/
├── algorithms/       # Framework desacoplado de algoritmos (plugins modulares)
├── application/      # Providers de Riverpod, Notifiers y Estado inmutable
├── domain/           # Modelos, interfaces puras y lógica de negocio (Dart puro)
└── ui/               # Presentación: Canvas, Painter, Widgets, Screens y Diálogos
```

### Reglas de Oro de Arquitectura
1. **Regla de Dependencia (Capas Limpias):**
   - `domain/` **NUNCA** debe importar `package:flutter/material.dart` ni librerías de UI. Debe ser código Dart 100% puro y comprobable con pruebas unitarias simples.
   - `application/` conoce `domain/`, pero no debe contener widgets de Flutter ni lógica visual.
   - `ui/` consume `application/` y `domain/`, y se encarga exclusivamente del renderizado y captura de eventos.
   - `algorithms/` encapsula cada algoritmo de forma autocontenida sin acoplar el núcleo del editor de grafos.
2. **Inmutabilidad:**
   - Todos los modelos de dominio (`Grafo`, `Nodo`, `Conexion`, `AtributoValor`) deben ser inmutables con constructores `const` y métodos `copyWith`.
   - Las colecciones en el estado no deben mutarse *in-place*; deben generarse nuevas instancias (e.g., `Map.from(state.nodos)..remove(id)`).
3. **Manejo de Estado con Riverpod:**
   - Usa `Notifier<T>` o `AsyncNotifier<T>` (Riverpod 2.0+).
   - Usa `ref.watch(provider)` dentro del método `build()` para reconstruir reactivamente.
   - Usa `ref.read(provider.notifier)` dentro de callbacks de eventos (`onPressed`, `onTap`, `showDialog`). **Nunca uses `ref.read` dentro del cuerpo de `build()`**.
   - Usa `select` cuando un widget solo dependa de una propiedad específica de un estado grande para evitar reconstrucciones innecesarias.

---

## 2. Sistema de Retroalimentación y Mensajes (Toasts)

> [!CAUTION]
> **PROHIBIDO** invocar `ScaffoldMessenger.of(context).showSnackBar(...)` directamente en pantallas o widgets nuevos.

### Uso Obligatorio de `AppToast`
Todo mensaje informativo, de error, confirmación o advertencia debe emitirse mediante [`AppToast`](file:///c:/Users/adm/Music/nodos/nodos/lib/ui/widgets/app_toast.dart):

```dart
import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';

// Mensaje estándar informativo
AppToast.show(
  context,
  'Algoritmo calculado con éxito.',
  icon: Icons.check_circle_rounded,
);

// Mensaje de advertencia o denegación de política
AppToast.show(
  context,
  'El algoritmo activo no permite auto-conexiones.',
  icon: Icons.block_rounded,
  backgroundColor: Colors.red.shade800,
  textColor: Colors.white,
  duration: const Duration(seconds: 3),
);
```

**Por qué:** `AppToast` implementa una píldora flotante animada con sombras suaves, compatibilidad de temas claro/oscuro y respeto del espacio de barras y paneles inferiores sin empujar la interfaz.

---

## 3. Diálogos, Menús y Flujos de Navegación

### Menús y Paneles Flotantes
1. **Acciones Contextuales en Lienzo:** Al presionar o hacer clic secundario en un elemento del lienzo, se dispara [`FloatingContextMenu`](file:///c:/Users/adm/Music/nodos/nodos/lib/ui/widgets/floating_context_menu.dart).
2. **Resolución de Clics Superpuestos:** Cuando el usuario pulsa sobre una zona con varios nodos o aristas solapadas, se debe abrir [`OverlappingElementsDialog`](file:///c:/Users/adm/Music/nodos/nodos/lib/ui/dialogs/overlapping_elements_dialog.dart) para que el usuario elija explícitamente el elemento.
3. **Panel de Edición Inferior (`EditPanel`):** Aparece al seleccionar un nodo o conexión. Ofrece edición de colores, nombre, curvatura de aristas y controles específicos inyectados por el algoritmo activo.
4. **Navegación Web Educativa (`WebExplanationShell`):** Toda pantalla de contenido informativo o teórico debe embeberse dentro de `WebExplanationShell` para contar con la barra de navegación superior, drawer lateral responsivo y transición fluida entre la teoría y el editor.

### Confirmación de Cambios No Guardados
Al salir de pantallas críticas o cerrar modales de edición, intercepta el pop usando `PopScope` y consulta si hay cambios pendientes antes de descartarlos.

---

## 4. Sistema de Matrices Personalizadas y `MatrixViewCoordinator`

Las matrices en la aplicación son polimórficas y se adaptan a la topología y formulación de cada algoritmo:

### 4.1 Coordinador Central (`MatrixViewCoordinator`)
Cuando el usuario presiona el botón de matriz en la barra superior o drawer, **siempre** se invoca:
```dart
MatrixViewCoordinator.openMatrix(context, ref);
```
El flujo de decisión es:
1. **Modo Libre:** Valida conectividad mediante `esGrafoInvalidoProvider`. Si hay nodos desconectados, muestra un `AppToast`. Si es conexo, navega a [`AdjacencyMatrixScreen`](file:///c:/Users/adm/Music/nodos/nodos/lib/ui/dialogs/adjacency_matrix_dialog.dart).
2. **Modo Algoritmo sin Matriz (`supportsMatrix == false`):** Emite un `AppToast` explicativo con el motivo (`matrixUnavailableReason`), como en Johnson/CPM.
3. **Modo Algoritmo con Matriz (`supportsMatrix == true`):** Llama polimórficamente a `algorithm.buildMatrixScreen(context, ref)` y realiza la navegación.

### 4.2 Cómo Implementar una Pantalla Matricial Personalizada
Para algoritmos que requieren vistas matriciales (por ejemplo: Asignación/Transporte, Floyd-Warshall, Matriz de Costos/Capacidades):

1. **Estructura Visual con Doble Desplazamiento:**
   Para soportar grafos de cualquier número de nodos/aristas sin desbordamientos de pantalla (`overflow`), anida dos `SingleChildScrollView` en direcciones ortogonales:
   ```dart
   SingleChildScrollView(
     scrollDirection: Axis.vertical,
     child: SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: MiTablaMatricialWidget(...),
       ),
     ),
   )
   ```
2. **Celdas Interactivas y Resaltado:**
   - Permite seleccionar filas o columnas almacenando `int? _selectedRowIndex` y `int? _selectedColumnIndex`.
   - Modifica el color de fondo o borde de las celdas coincidentes para mejorar la legibilidad.
3. **Edición de Valores en Matriz:**
   - **Edición en Línea:** Al pulsar una celda editable, abre un diálogo numérico o activa un input directo, persistiendo el cambio inmediatamente en `grafoProvider`:
     ```dart
     ref.read(grafoProvider.notifier).actualizarConexion(
       conexion.id,
       atributos: [AtributoValor(atributoId: 'attr_valor', valor: nuevoValor)],
     );
     ```
   - **Edición por Lotes (Batch Dialog):** Si se permite editar la matriz completa en una sola vista (e.g. [`AssignmentMatrixInputDialog`](file:///c:/Users/adm/Music/nodos/nodos/lib/algorithms/assignment/ui/assignment_matrix_input_dialog.dart)), mantén controladores `TextEditingController` por celda, valida números válidos (> 0, no negativos, etc.), muestra micro-animaciones en rojo al ingresar datos inválidos, y usa `PopScope` para consultar al usuario antes de salir si hay cambios sin guardar.

---

## 5. Sistema de Diálogos y Popups de Entrada Personalizados

Diferentes algoritmos exigen semánticas distintas para los valores de sus aristas y nodos (costos, capacidades, holguras, probabilidades, oferta/demanda).

### 5.1 Personalización de Entradas de Conexión (Aristas)

El contrato [`GraphAlgorithm`](file:///c:/Users/adm/Music/nodos/nodos/lib/algorithms/core/graph_algorithm.dart) expone dos hooks para controlar la captura de valores:

```dart
/// Abre el diálogo al editar el valor de una conexión existente
Future<bool?> showConnectionValueInputDialog(
  BuildContext context,
  WidgetRef ref,
  Conexion conexion,
);

/// Se dispara automáticamente cuando el usuario traza una nueva arista en el lienzo
Future<void> onConnectionCreated(
  BuildContext context,
  WidgetRef ref,
  Conexion conexion,
);
```

#### Opción A: Configuración Rápida con `ConnectionValueInputDialog`
Si el algoritmo solo necesita un valor numérico único (ej. costo o duración), reutiliza [`ConnectionValueInputDialog`](file:///c:/Users/adm/Music/nodos/nodos/lib/ui/dialogs/connection_value_input_dialog.dart) especificando el título y la etiqueta:

```dart
@override
Future<bool?> showConnectionValueInputDialog(
  BuildContext context,
  WidgetRef ref,
  Conexion conexion,
) {
  return ConnectionValueInputDialog.show(
    context: context,
    ref: ref,
    conexion: conexion,
    title: 'Duración de la Actividad ($shortName)',
    valueLabel: 'Duración (en días o semanas)',
  );
}
```

#### Opción B: Diálogo Modal Personalizado Multi-Campo
Si el algoritmo requiere múltiples parámetros por conexión (por ejemplo, **Flujo Máximo con Costo Mínimo**: capacidad $u_{ij}$ y costo unitario $c_{ij}$), crea un diálogo dedicado en `lib/algorithms/<nombre>/ui/`:

```dart
class FlujoCapacidadInputDialog extends ConsumerStatefulWidget {
  final Conexion conexion;
  const FlujoCapacidadInputDialog({super.key, required this.conexion});

  static Future<void> show(BuildContext context, Conexion conexion) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FlujoCapacidadInputDialog(conexion: conexion),
    );
  }
  ...
}
```

Y sobrescribe en tu implementación de `GraphAlgorithm`:
```dart
@override
Future<void> onConnectionCreated(
  BuildContext context,
  WidgetRef ref,
  Conexion conexion,
) {
  FlujoCapacidadInputDialog.show(context, conexion);
  return Future.value();
}
```

**Guardado de Atributos:** Almacena los valores dentro de la lista inmutable `atributos` de la conexión:
```dart
ref.read(grafoProvider.notifier).actualizarConexion(
  conexion.id,
  atributos: [
    AtributoValor(atributoId: 'capacidad', valor: capacidadController.text.trim()),
    AtributoValor(atributoId: 'costo', valor: costoController.text.trim()),
  ],
);
```

### 5.2 Personalización de Entradas y Propiedades de Nodos

Para algoritmos donde los nodos tienen pesos, demandas, ofertas o roles específicos:

1. **Inicialización y Rol en la Política:**
   En `GraphAlgorithmPolicy.prepareNewNode`, asigna los atributos por defecto o roles del nodo recién creado:
   ```dart
   @override
   Nodo prepareNewNode(Grafo grafo, double x, double y, {String? nombre, int? colorValue, Map<String, dynamic>? params}) {
     return Nodo(
       id: 'node_${DateTime.now().millisecondsSinceEpoch}',
       x: x,
       y: y,
       nombre: nombre ?? 'Nodo',
       rol: 'oferta', // o rol asignado
       atributos: const [
         AtributoValor(atributoId: 'capacidad_produccion', valor: '100'),
       ],
     );
   }
   ```

2. **Inyección en el Panel Inferior (`EditPanel`):**
   Sobrescribe `buildNodeEditControls` en tu clase de `GraphAlgorithm` para incrustar widgets reactivos directamente en la sección de propiedades del nodo cuando el usuario lo selecciona:
   ```dart
   @override
   Widget? buildNodeEditControls(
     BuildContext context,
     WidgetRef ref,
     Nodo nodo,
   ) {
     return Row(
       children: [
         const Text('Oferta: '),
         SizedBox(
           width: 80,
           child: TextField(
             keyboardType: TextInputType.number,
             onSubmitted: (val) {
               ref.read(grafoProvider.notifier).actualizarNodo(
                 nodo.id,
                 atributos: [AtributoValor(atributoId: 'oferta', valor: val)],
               );
             },
           ),
         ),
       ],
     );
   }
   ```

3. **Popups Modales para Propiedades de Nodo:**
   Si las propiedades del nodo son extensas, coloca un botón dentro de `buildNodeEditControls` que invoque un modal dedicado (`showDialog(...)`) con validación y confirmación.

---

## 6. Guía Paso a Paso: Cómo Crear un Nuevo Algoritmo

Para agregar un nuevo algoritmo al proyecto (por ejemplo: Dijkstra, Ford-Fulkerson, Kruskal, etc.), sigue esta estructura estandarizada dentro de `lib/algorithms/<nombre_algoritmo>/`:

```
lib/algorithms/<nombre_algoritmo>/
├── <nombre_algoritmo>_algorithm.dart  # Implementación de GraphAlgorithm
├── domain/
│   ├── models/                         # Modelos inmutables de resultados/cálculos
│   ├── policy/                         # Implementación de GraphAlgorithmPolicy
│   ├── services/                       # Validadores y transformadores de grafos
│   └── solvers/                        # Solvers matemáticos puros (Dart puro)
├── providers/                          # Riverpod Providers y Notifiers
└── ui/
    ├── <nombre>_launch_button.dart     # Botón para la web explicativa
    ├── <nombre>_canvas_controls.dart   # Controles flotantes en el lienzo (opcional)
    ├── <nombre>_algorithm_card.dart    # Tarjeta de resultados flotante (opcional)
    ├── <nombre>_matrix_screen.dart     # Matriz dedicada (si aplica)
    └── <nombre>_input_dialog.dart      # Diálogo de entrada personalizado (si aplica)
```

### Paso 1: Crear la Política de Dibujo (`GraphAlgorithmPolicy`)
Crea `domain/policy/<nombre>_graph_policy.dart` heredando de [`GraphAlgorithmPolicy`](file:///c:/Users/adm/Music/nodos/nodos/lib/algorithms/core/graph_algorithm.dart):

```dart
import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../core/graph_algorithm.dart';

class MiAlgoritmoGraphPolicy extends GraphAlgorithmPolicy {
  const MiAlgoritmoGraphPolicy();

  @override
  PolicyResult canCreateNode(Grafo grafo, double x, double y, {Map<String, dynamic>? params}) {
    return const PolicyResult.allow();
  }

  @override
  Nodo prepareNewNode(Grafo grafo, double x, double y, {String? nombre, int? colorValue, Map<String, dynamic>? params}) {
    final nextIndex = grafo.nodos.length + 1;
    return Nodo(
      id: 'node_$nextIndex',
      x: x,
      y: y,
      nombre: nombre ?? 'Nodo $nextIndex',
      colorValue: colorValue ?? 0xFF2196F3,
    );
  }

  @override
  PolicyResult canCreateConnection(Grafo grafo, String origenId, String destinoId, Direccion direccion) {
    if (origenId == destinoId && !allowSelfLoops) {
      return const PolicyResult.deny('No se permiten auto-bucles en este algoritmo.');
    }
    return const PolicyResult.allow();
  }

  @override
  List<Direccion> allowedDirections(Grafo grafo, String origenId, String destinoId) {
    return const [Direccion.unidireccional];
  }

  @override
  bool get allowSelfLoops => false;

  @override
  bool get allowBidirectional => false;
}
```

### Paso 2: Implementar la Lógica Matemática (Solver en `domain/solvers/`)
Escribe una clase de Dart puro sin dependencias de Flutter:

```dart
class MiAlgoritmoSolver {
  static MiResultado solve(Grafo grafo, String startNodeId) {
    // Lógica pura de cálculo
    return MiResultado(...);
  }
}
```

### Paso 3: Crear los Providers de Estado (`providers/`)
Expón los resultados y la capa de resaltado visual para el lienzo:

```dart
final miAlgoritmoResultProvider = Provider<MiResultado?>((ref) {
  final grafo = ref.watch(grafoProvider);
  if (grafo.nodos.isEmpty) return null;
  return MiAlgoritmoSolver.solve(grafo, ...);
});

// Resaltado de nodos y aristas para la capa glow del lienzo
final miAlgoritmoHighlightProvider = Provider<AlgorithmHighlight>((ref) {
  final result = ref.watch(miAlgoritmoResultProvider);
  if (result == null) return const AlgorithmHighlight();

  return AlgorithmHighlight(
    algorithmName: 'Mi Algoritmo',
    nodeIds: result.nodosSolucion,
    connectionIds: result.aristasSolucion,
  );
});
```

### Paso 4: Implementar el Contrato [`GraphAlgorithm`](file:///c:/Users/adm/Music/nodos/nodos/lib/algorithms/core/graph_algorithm.dart)
Crea `<nombre>_algorithm.dart` integrando políticas, matriz y controles de entrada:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/graph_algorithm.dart';
import 'domain/policy/mi_algoritmo_graph_policy.dart';
import 'ui/mi_algoritmo_launch_button.dart';
import 'ui/mi_algoritmo_algorithm_card.dart';

class MiAlgoritmo extends GraphAlgorithm {
  static const String algorithmId = 'mi_algoritmo';

  const MiAlgoritmo();

  @override
  String get id => algorithmId;
  @override
  String get name => 'Algoritmo de Prueba';
  @override
  String get shortName => 'Prueba';
  @override
  String get description => 'Calcula rutas y optimizaciones.';
  @override
  IconData get icon => Icons.alt_route_rounded;
  @override
  Color get themeColor => Colors.teal;

  @override
  GraphAlgorithmPolicy get policy => const MiAlgoritmoGraphPolicy();

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) => const MiAlgoritmoLaunchButton();

  @override
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) => const MiAlgoritmoAlgorithmCard();

  @override
  bool get supportsMatrix => true;

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) => const MiMatrizScreen();
}
```

### Paso 5: Registrar el Algoritmo en [`AlgorithmRegistry`](file:///c:/Users/adm/Music/nodos/nodos/lib/algorithms/core/algorithm_registry.dart)
Añade la instancia en `lib/algorithms/core/algorithm_registry.dart`:

```dart
class AlgorithmRegistry {
  static const String miAlgoritmoId = MiAlgoritmo.algorithmId;

  static final List<GraphAlgorithm> registeredAlgorithms = [
    const AssignmentAlgorithm(),
    const JohnsonAlgorithm(),
    const MiAlgoritmo(), // <-- Registrado aquí
  ];
  ...
}
```
Y añade el reset del estado en `ActiveAlgorithmNotifier._syncAlgorithmNotifiers` para asegurar que al cambiar de algoritmo se limpie la ejecución previa.

---

## 7. Reglas de Estilo y Buenas Prácticas para Widgets

1. **Gestión de Recursos y Controladores:**
   - Todo `TextEditingController`, `FocusNode`, `ScrollController` o `AnimationController` instanciado en un `StatefulWidget` o `ConsumerStatefulWidget` **DEBE** ser liberado en el método `dispose()`.
2. **Uso de Tema:**
   - Usa siempre `Theme.of(context).colorScheme` y `AppTheme`.
   - Evita colores fijos o valores `Colors.blue` directos; prefiere `colorScheme.primary`, `colorScheme.surface`, `colorScheme.onSurface`, etc., para garantizar el funcionamiento del modo oscuro.
3. **Widgets Modulares y Atómicos:**
   - Evita métodos `Widget _buildX()` gigantescos que dependan de muchas variables externas. Prefiere componentes separados en clases privadas o públicas (`_MiSubComponente extends StatelessWidget`).
4. **Validación de Formularios e Inputs:**
   - Valida siempre valores numéricos de aristas (evitar valores negativos o NaN donde no correspondan).
   - Proporciona retroalimentación visual al usuario (bordes rojos, micro-animaciones) en vez de fallar silenciosamente.

---

## 8. Estrategia de Pruebas Automatizadas (Testing)

Cada nuevo algoritmo, pantalla, diálogo o validador incorporado al proyecto debe contar con pruebas automatizadas que garanticen su estabilidad a largo plazo:

### 8.1 Niveles de Prueba
1. **Pruebas de Políticas de Dibujo (`test/unit/algorithms/`):**
   - Verificar que `canCreateNode` y `canCreateConnection` rechacen y admitan las operaciones según las reglas del algoritmo (por ejemplo: prohibir auto-bucles, restringir direcciones bidireccionales o impedir ciclos en DAGs).
2. **Pruebas de Solvers y Dominio Matemático (`test/unit/domain/`):**
   - Evaluar los algoritmos puros de cálculo (como el solver de Asignación Húngara o el cálculo de Ruta Crítica de Johnson) con grafos de prueba balanceados, desbalanceados y casos límite sin dependencias de Flutter.
3. **Pruebas de Widgets y UI Reactiva (`test/widget/`):**
   - Verificar la renderización y respuesta de diálogos, matrices interactivas y paneles de edición utilizando `ProviderScope(overrides: [...])` con notifiers simulados:
   ```dart
   testWidgets('Abre la pantalla de matriz correctamente', (tester) async {
     await tester.pumpWidget(
       ProviderScope(
         overrides: [
           grafoProvider.overrideWith(() => MockGrafoNotifier(grafoPrueba)),
           activeAlgorithmProvider.overrideWith(() => MockActiveAlgoNotifier(miAlgoritmo)),
         ],
         child: const MaterialApp(home: Scaffold(body: MiMatrizScreen())),
       ),
     );
     expect(find.byType(MiMatrizScreen), findsOneWidget);
   });
   ```

### 8.2 Comandos de Ejecución de Pruebas
- **Ejecutar toda la suite:**
  ```bash
  flutter test
  ```
- **Ejecutar por categorías:**
  ```bash
  # Pruebas unitarias de dominio y solvers
  flutter test test/unit/

  # Pruebas de widgets y diálogos
  flutter test test/widget/
  ```
- **Fallo rápido en desarrollo:**
  ```bash
  flutter test --fail-fast
  ```
- **Generar reporte de cobertura de código (Coverage):**
  ```bash
  flutter test --coverage
  ```
  *(Genera el archivo `coverage/lcov.info` compatible con herramientas de reporte).*

---

## 9. Calidad de Código, Formateo y Flujo de CI (Integración Continua)

Para mantener la consistencia del código y asegurar que los pipelines de CI pasen sin fricción, sigue estas pautas obligatorias:

### 9.1 Formateo de Código (`dart format`)
Todo archivo Dart debe seguir el estilo oficial estándar de 80 columnas de Dart:

- **Formatear automáticamente todos los archivos del proyecto:**
  ```bash
  dart format .
  ```
- **Comprobación estricta para CI (falla si hay archivos sin formatear):**
  ```bash
  dart format --output=none --set-exit-if-changed .
  ```

### 9.2 Análisis Estático (`flutter analyze`)
El proyecto se rige por las reglas oficiales de [`package:flutter_lints/flutter.yaml`](file:///c:/Users/adm/Music/nodos/nodos/analysis_options.yaml).

- **Ejecutar análisis en local:**
  ```bash
  flutter analyze
  ```
- **Ejecutar análisis estricto en CI:**
  ```bash
  flutter analyze --fatal-infos --fatal-warnings
  ```
> [!IMPORTANT]
> **Regla de Oro:** No se permiten commits ni Pull Requests con advertencias (*warnings*), errores (*errors*) ni imports no utilizados en `lib/` ni en `test/`.

### 9.3 Lista de Verificación Antes de Crear Commits / PRs (Pre-Push Checklist)
Antes de enviar cambios o solicitar revisión, ejecuta la siguiente secuencia en tu terminal:

```bash
# 1. Formatear el código
dart format .

# 2. Verificar que no haya advertencias de linter
flutter analyze

# 3. Ejecutar y pasar el 100% de las pruebas
flutter test

```

### 9.4 Plantilla de Pipeline para GitHub Actions (`.github/workflows/ci.yml`)
Si configuras o actualizas el pipeline de CI en GitHub Actions, utiliza este flujo optimizado:

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    name: Code Quality & Automated Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: flutter pub get

      - name: Verify Code Formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Static Code Analysis
        run: flutter analyze --fatal-infos --fatal-warnings

      - name: Run Unit and Widget Tests
        run: flutter test --coverage
```

