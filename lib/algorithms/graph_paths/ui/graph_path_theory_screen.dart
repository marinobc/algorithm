import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui/widgets/video_resource_card.dart';
import '../../../ui/widgets/web_explanation_navbar.dart';
import '../graph_path_algorithm.dart';

class GraphPathTheoryScreen extends ConsumerWidget {
  final bool kruskal;
  const GraphPathTheoryScreen.dijkstra({super.key}) : kruskal = false;
  const GraphPathTheoryScreen.kruskal({super.key}) : kruskal = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final algorithm = kruskal
        ? const GraphPathAlgorithm.kruskal()
        : const GraphPathAlgorithm.dijkstra();
    final color = algorithm.themeColor;
    final scheme = Theme.of(context).colorScheme;
    final videoResources = kruskal
        ? const <(String, String, String)>[
            (
              'Kruskal explicado en dos minutos',
              'Repasa la idea central: ordenar aristas por peso y conservar solo las que conectan componentes distintas.',
              'https://www.youtube.com/watch?v=71UQH7Pr9kU',
            ),
            (
              'Union-Find y Kruskal',
              'Conoce cómo la estructura de conjuntos disjuntos identifica componentes y ayuda a detectar ciclos.',
              'https://www.youtube.com/watch?v=JZBQLXgSGfs',
            ),
            (
              'Construcción del árbol de expansión',
              'Sigue otro recorrido visual del algoritmo y observa cómo se forma el árbol de expansión mínima.',
              'https://www.youtube.com/watch?v=OxfTT8slSLs',
            ),
          ]
        : const <(String, String, String)>[
            (
              'Dijkstra paso a paso',
              'Explora la selección del vértice con menor distancia y la actualización de sus vecinos.',
              'https://www.youtube.com/watch?v=EFg3u_E6eHU&t=439s',
            ),
            (
              'Ejemplo de caminos mínimos',
              'Refuerza el uso de distancias tentativas, vértices visitados y reconstrucción de la ruta.',
              'https://www.youtube.com/watch?v=bZkzH5x0SKU',
            ),
            (
              'Dijkstra en teoría de grafos',
              'Repasa el problema que resuelve y las decisiones que toma el algoritmo en cada iteración.',
              'https://www.youtube.com/watch?v=GazC3A4OQTE',
            ),
          ];
    final sections = kruskal
        ? const <(String, String, IconData)>[
            (
              'El problema: conectar con el menor costo',
              'Un árbol de expansión conecta todos los vértices de un grafo no dirigido, sin ciclos y con exactamente |V|−1 aristas. Kruskal elige el árbol cuya suma de pesos es mínima. Si el grafo tiene varias componentes, obtiene un bosque mínimo para cada una.',
              Icons.account_tree_outlined,
            ),
            (
              'La elección voraz y su seguridad',
              'Ordena las aristas de menor a mayor y toma la más liviana que conecte dos componentes distintas. La propiedad del corte explica por qué esa arista es segura: es la de menor peso que cruza una separación entre componentes aún desconectadas.',
              Icons.rule_rounded,
            ),
            (
              'Cómo detecta y evita ciclos',
              'Cada vértice empieza en su propio conjunto. Union-Find consulta si los extremos de una arista ya pertenecen al mismo componente: si sí, la descarta porque cerraría un ciclo; si no, la agrega y une los conjuntos. El proceso termina al conectar cada componente.',
              Icons.hub_outlined,
            ),
            (
              'Mínimo, máximo y pesos iguales',
              'El orden ascendente obtiene el bosque mínimo; el descendente obtiene el máximo. Se admiten pesos negativos, cero y positivos. Si varias aristas empatan, puede haber más de un árbol óptimo con el mismo peso total.',
              Icons.swap_vert_rounded,
            ),
            (
              'Ejemplo y resultado',
              'Con A–B (1), B–C (2) y A–C (5), el mínimo acepta los pesos 1 y 2: total 3; rechaza 5 porque cerraría un ciclo. En modo máximo acepta 5 y 2: total 7. Para un grafo conectado se seleccionan |V|−1 aristas.',
              Icons.functions_rounded,
            ),
            (
              'Costo y aplicaciones',
              'Se aplica al planear redes de cables, fibra o caminos con costo total bajo. El ordenamiento domina el tiempo: O(E log E); Union-Find mantiene componentes con operaciones casi constantes amortizadas. El laboratorio también puede invertir el orden para construir un bosque máximo.',
              Icons.cable_rounded,
            ),
          ]
        : const <(String, String, IconData)>[
            (
              'El problema: rutas de menor costo',
              'Dijkstra calcula desde un origen la distancia mínima a cada vértice alcanzable en un grafo dirigido o no dirigido. El peso puede representar distancia, duración, consumo u otra magnitud que se acumula al recorrer las aristas.',
              Icons.route_rounded,
            ),
            (
              'Inicialización y relajación',
              'Asigna distancia 0 al origen e infinito a los demás. Para cada arista u→v prueba si d(u)+peso(u,v) mejora d(v); si mejora, actualiza d(v) y guarda u como predecesor. Esta actualización se llama relajación.',
              Icons.table_chart_outlined,
            ),
            (
              'Por qué se fija el menor valor',
              'En cada iteración visita el vértice pendiente con menor distancia tentativa. Como los pesos son no negativos, ninguna ruta futura que pase por otro vértice puede reducir ese valor. Por eso su distancia queda definitiva y se puede expandir con seguridad.',
              Icons.verified_outlined,
            ),
            (
              'Reconstrucción e interpretación',
              'Al terminar, sigue los predecesores desde el destino hasta el origen y luego invierte la secuencia. Si un vértice conserva distancia infinita, no existe una ruta desde el origen. Cuando hay empates, distintas rutas pueden compartir el mismo costo mínimo.',
              Icons.functions_rounded,
            ),
            (
              'Límites y complejidad',
              'Dijkstra clásico requiere pesos mayores o iguales que cero; con pesos negativos puede fijar una distancia antes de encontrar una ruta mejor. Este laboratorio selecciona el mínimo directamente y cuesta O(V² + E). El modo de camino máximo simple es otro problema: usa orden topológico en DAG y búsqueda acotada en otros grafos.',
              Icons.map_outlined,
            ),
            (
              'Usos cotidianos',
              'Puede modelar navegación por calles, rutas de paquetes en una red o conexiones entre estaciones. El resultado depende de cómo definas el peso: kilómetros para distancia, minutos para duración o una penalización para evitar ciertos tramos.',
              Icons.public_rounded,
            ),
          ];

    return WebExplanationShell(
      activePage: kruskal
          ? ExplanationWebPage.kruskal
          : ExplanationWebPage.dijkstra,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: .25), scheme.surface],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: .3),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: color.withValues(alpha: .4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kruskal
                                  ? Icons.account_tree_outlined
                                  : Icons.route_rounded,
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              kruskal
                                  ? 'Árbol de expansión mínima'
                                  : 'Caminos mínimos desde un origen',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        algorithm.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 750),
                        child: Text(
                          algorithm.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                height: 1.55,
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _TopicChip(
                            label: kruskal
                                ? 'Árbol de expansión'
                                : 'Rutas mínimas',
                            color: color,
                          ),
                          _TopicChip(
                            label: kruskal
                                ? 'Union-Find'
                                : 'Pesos no negativos',
                            color: color,
                          ),
                          _TopicChip(
                            label: kruskal ? 'Sin ciclos' : 'Desde un origen',
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      algorithm.buildLaunchButton(context, ref),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 42,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        for (final (title, description, icon) in sections)
                          SizedBox(
                            width: constraints.maxWidth >= 1018
                                ? (constraints.maxWidth - 18) / 2
                                : constraints.maxWidth,
                            child: Card(
                              color: scheme.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(icon, color: color, size: 32),
                                    const SizedBox(height: 15),
                                    Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _TheoryExample(kruskal: kruskal, color: color),
            _VideoLearningSection(
              title: kruskal ? 'Kruskal en video' : 'Dijkstra en video',
              subtitle: kruskal
                  ? 'Tres explicaciones para entender el orden de las aristas, la detección de ciclos y Union-Find.'
                  : 'Videos para seguir las distancias tentativas, las relajaciones y la reconstrucción de una ruta.',
              resources: videoResources,
              color: color,
            ),
            _ReferenceSection(kruskal: kruskal, color: color),
            _GraphPathCallToAction(algorithm: algorithm, color: color),
          ],
        ),
      ),
    );
  }
}

class _TheoryExample extends StatelessWidget {
  final bool kruskal;
  final Color color;
  const _TheoryExample({required this.kruskal, required this.color});

  @override
  Widget build(BuildContext context) {
    final steps = kruskal
        ? const [
            'Orden ascendente: A–B (1), B–C (2), A–C (5).',
            'Aceptar A–B: une {A} y {B}; total 1.',
            'Aceptar B–C: une {A,B} y {C}; total 3.',
            'Rechazar A–C: cerraría un ciclo. En orden descendente, el máximo suma 7.',
          ]
        : const [
            'Inicio en A: d(A)=0, d(B)=∞, d(C)=∞.',
            'Fijar A: relajar A–B (1) y A–C (5); B=1, C=5.',
            'Fijar B: 1+2=3 mejora C de 5 a 3; predecesor de C=B.',
            'Fijar C y retroceder C←B←A: ruta A–B–C de costo 3.',
          ];
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: .05),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ejemplo guiado · A–B–C',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 24,
                    runSpacing: 18,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth >= 750
                            ? 350
                            : constraints.maxWidth,
                        height: 215,
                        child: Card(
                          color: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CustomPaint(
                              painter: _ExampleGraphPainter(color),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 750
                            ? constraints.maxWidth - 374
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: color,
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        steps[i],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TopicChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withValues(alpha: .28)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _VideoLearningSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(String, String, String)> resources;
  final Color color;
  const _VideoLearningSection({
    required this.title,
    required this.subtitle,
    required this.resources,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'APRENDE CON VIDEOS',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;
                    final gap = 16.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final (videoTitle, description, url) in resources)
                          SizedBox(
                            width: width,
                            child: VideoResourceCard(
                              title: videoTitle,
                              description: description,
                              videoUrl: url,
                              durationOrAuthor: 'Recurso de aprendizaje',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceSection extends StatelessWidget {
  final bool kruskal;
  final Color color;
  const _ReferenceSection({required this.kruskal, required this.color});

  @override
  Widget build(BuildContext context) {
    final source = kruskal
        ? (
            'Princeton Algorithms · Minimum Spanning Trees',
            'https://algs4.cs.princeton.edu/43mst/index.php',
          )
        : (
            'Boost Graph Library · Dijkstra Shortest Paths',
            'https://www.boost.org/doc/libs/latest/libs/graph/doc/dijkstra_shortest_paths.html',
          );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fuentes para profundizar',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Referencia técnica consultada para esta explicación.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(source.$2)),
                icon: Icon(Icons.open_in_new_rounded, color: color),
                label: Text(source.$1, style: TextStyle(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraphPathCallToAction extends ConsumerWidget {
  final GraphPathAlgorithm algorithm;
  final Color color;
  const _GraphPathCallToAction({required this.algorithm, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final title = algorithm.kruskal
        ? '¡Construye tu árbol con Kruskal!'
        : '¡Encuentra una ruta con Dijkstra!';
    final description = algorithm.kruskal
        ? 'Crea un grafo, asigna pesos a sus aristas y observa cómo se forma el árbol de expansión.'
        : 'Dibuja un grafo ponderado, elige origen y destino, y sigue cada decisión del algoritmo.';

    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 38),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [color, color.withValues(alpha: .82)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: .9),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Theme(
                  data: Theme.of(context).copyWith(
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.surface,
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  child: algorithm.buildLaunchButton(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleGraphPainter extends CustomPainter {
  final Color color;
  const _ExampleGraphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(size.width * .14, size.height * .78);
    final b = Offset(size.width * .5, size.height * .18);
    final c = Offset(size.width * .86, size.height * .78);
    final line = Paint()
      ..color = color.withValues(alpha: .75)
      ..strokeWidth = 3;
    canvas.drawLine(a, b, line);
    canvas.drawLine(b, c, line);
    canvas.drawLine(a, c, line);
    void label(String value, Offset position, {double size = 15, Color? ink}) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: ink ?? color,
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }

    for (final (name, point) in [('A', a), ('B', b), ('C', c)]) {
      canvas.drawCircle(point, 18, Paint()..color = color);
      label(name, point, ink: Colors.white);
    }
    label('1', Offset((a.dx + b.dx) / 2 - 12, (a.dy + b.dy) / 2));
    label('2', Offset((b.dx + c.dx) / 2 + 12, (b.dy + c.dy) / 2));
    label('5', Offset((a.dx + c.dx) / 2, a.dy - 17));
  }

  @override
  bool shouldRepaint(covariant _ExampleGraphPainter oldDelegate) =>
      oldDelegate.color != color;
}
