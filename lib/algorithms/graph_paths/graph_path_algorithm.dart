import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../../ui/screens/graph_editor_screen.dart';
import '../core/algorithm_registry.dart';
import '../core/graph_algorithm.dart';
import 'domain/graph_path_policy.dart';
import 'providers/graph_path_run_provider.dart';
import 'ui/graph_path_matrix_screen.dart';
import 'ui/graph_path_canvas_controls.dart';
import 'ui/graph_path_colors.dart';
import 'ui/graph_path_weight_dialog.dart';

class GraphPathAlgorithm extends GraphAlgorithm {
  static const dijkstraId = 'dijkstra';
  static const kruskalId = 'kruskal';

  final bool kruskal;
  const GraphPathAlgorithm.dijkstra() : kruskal = false;
  const GraphPathAlgorithm.kruskal() : kruskal = true;

  @override
  String get id => kruskal ? kruskalId : dijkstraId;

  @override
  String get name => kruskal ? 'Kruskal' : 'Dijkstra';

  @override
  String get shortName => name;

  @override
  String get description => kruskal
      ? 'Construye árboles o bosques de expansión de peso mínimo o máximo.'
      : 'Encuentra caminos mínimos con pesos no negativos y explora caminos máximos simples.';

  @override
  IconData get icon =>
      kruskal ? Icons.account_tree_outlined : Icons.route_rounded;

  @override
  Color get themeColor =>
      kruskal ? GraphPathColors.kruskalAccent : GraphPathColors.dijkstraAccent;

  @override
  String get userGuideMarkdown => kruskal ? _kruskalGuide : _dijkstraGuide;

  static const _dijkstraGuide = '''
# Guía de uso · Dijkstra

1. Usa el mismo editor de grafos de Asignación y Johnson: toca el lienzo para crear vértices, arrástralos para moverlos y arrastra entre dos vértices para crear una arista. Toca un elemento para editarlo en el panel compartido.
2. Cada arista necesita un peso finito. Para Dijkstra clásico debe ser **cero o positivo**. Una arista sin flecha se recorre en ambos sentidos.
3. El laboratorio propone automáticamente origen y destino. Si el grafo dirigido tiene una única entrada y una única salida, las detecta por grado; en otros casos propone el primer y último vértice creados. Abre el menú contextual de un nodo o selecciónalo para cambiar sus extremos.
4. Elige **Camino mínimo** para Dijkstra o **Camino máximo simple** desde el control compacto del lienzo. Este último usa orden topológico en un DAG y DFS limitado en otros grafos.
5. Pulsa **Calcular ruta** abajo a la derecha y usa Reproducir, Pausa, Anterior, Siguiente, Reiniciar, deslizador y velocidad para revisar cada decisión. La tabla y el grafo siguen el mismo paso.
6. El menú principal contiene Nuevo, Guardar, Cargar y la matriz. Si editas el grafo, los pasos calculados se invalidan.
''';

  static const _kruskalGuide = '''
# Guía de uso · Kruskal

1. Construye un grafo **no dirigido** en el canvas compartido. Toca para crear vértices, arrastra entre ellos para conectarlos y usa el panel de edición para cambiar datos. Kruskal no convertirá automáticamente aristas dirigidas existentes.
2. Ingresa pesos finitos: se admiten negativos, cero y positivos. Un bucle se rechaza porque forma un ciclo.
3. Elige **Mínimo** o **Máximo** en el control compacto y pulsa **Calcular árbol** abajo a la derecha. Kruskal utiliza todos los vértices y no necesita origen ni destino.
4. Cada paso muestra la arista candidata y sus componentes. Si une componentes diferentes se acepta; si forma un ciclo se rechaza.
5. Usa los controles de reproducción para retroceder o saltar a cualquier decisión. Si el grafo está desconectado, el resultado es un bosque que conserva los vértices aislados.
6. Nuevo, Guardar, Cargar y Matriz están en el menú principal. Si cargas un grafo con aristas dirigidas, corrígelas explícitamente antes de calcular.
''';

  @override
  GraphAlgorithmPolicy get policy => GraphPathPolicy(kruskal: kruskal);

  @override
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) =>
      GraphPathCanvasControls(kruskal: kruskal);

  @override
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) {
    if (kruskal) return null;
    final run = ref.watch(graphPathRunProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(graphPathRunProvider.notifier).setSource(nodo.id),
          icon: const Icon(Icons.trip_origin_rounded, size: 16),
          label: Text(
            run.sourceId == nodo.id ? 'Origen actual' : 'Fijar como origen',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(graphPathRunProvider.notifier).setTarget(nodo.id),
          icon: const Icon(Icons.flag_outlined, size: 16),
          label: Text(
            run.targetId == nodo.id ? 'Destino actual' : 'Fijar como destino',
          ),
        ),
      ],
    );
  }

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) =>
      FilledButton.icon(
        onPressed: () {
          ref.read(activeAlgorithmProvider.notifier).selectById(id);
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GraphEditorScreen()));
        },
        icon: Icon(icon),
        label: Text('Abrir laboratorio de $name'),
      );

  @override
  bool get supportsMatrix => true;

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) =>
      const GraphPathMatrixScreen();

  @override
  Future<bool?> showConnectionValueInputDialog(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) => GraphPathWeightDialog.show(
    context: context,
    connection: conexion,
    allowNegative:
        kruskal ||
        ref.read(graphPathRunProvider).mode == GraphPathMode.longestSimple,
  );

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) async {
    await GraphPathWeightDialog.show(
      context: context,
      connection: conexion,
      allowNegative:
          kruskal ||
          ref.read(graphPathRunProvider).mode == GraphPathMode.longestSimple,
      deleteOnCancel: true,
    );
  }
}
