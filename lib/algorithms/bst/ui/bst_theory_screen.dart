import 'package:flutter/material.dart';

import '../../../ui/widgets/video_resource_card.dart';
import '../../../ui/widgets/web_explanation_navbar.dart';
import 'bst_lab_screen.dart';

const _bstAccent = Color(0xFF7461AE);

class BstTheoryScreen extends StatelessWidget {
  const BstTheoryScreen({super.key});

  void _openLab(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BstLabScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return WebExplanationShell(
      activePage: ExplanationWebPage.bst,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _hero(context, colors),
            _division(
              context,
              colors,
              tone: _BstTone.surface,
              children: [
                _conceptCard(context, colors),
                const SizedBox(height: 36),
                _sectionHeading(
                  context,
                  eyebrow: 'LA REGLA DEL BST',
                  title: 'Cada comparación te acerca a un nodo',
                ),
                const SizedBox(height: 20),
                _ruleCards(context, colors),
                const SizedBox(height: 36),
                _treeExampleCard(context, colors),
              ],
            ),
            _division(
              context,
              colors,
              tone: _BstTone.low,
              children: [
                _sectionHeading(
                  context,
                  eyebrow: 'INSERCIÓN PASO A PASO',
                  title: '¿Dónde va el 4?',
                  description: 'Partimos del mismo árbol de ejemplo. Comparamos desde la raíz y seguimos la rama que indica cada resultado.',
                ),
                const SizedBox(height: 24),
                _insertionSteps(context, colors),
                const SizedBox(height: 24),
                _callout(
                  context,
                  colors,
                  icon: Icons.lightbulb_outline_rounded,
                  text: 'El orden en que insertas los valores cambia la forma del árbol. Un BST común no se rebalancea automáticamente.',
                ),
              ],
            ),
            _division(
              context,
              colors,
              tone: _BstTone.surface,
              children: [
                _sectionHeading(
                  context,
                  eyebrow: 'RECORRIDOS',
                  title: 'Los mismos nodos, tres órdenes',
                  description: 'Preorder e Inorder visitan raíz, ramas izquierda y derecha en órdenes distintos. Inorder entrega las claves ordenadas.',
                ),
                const SizedBox(height: 24),
                _traversalCards(context, colors),
              ],
            ),
            _division(
              context,
              colors,
              tone: _BstTone.low,
              children: [
                _sectionHeading(
                  context,
                  eyebrow: 'COSTE Y ESTRUCTURA',
                  title: 'La altura determina cuántos nodos revisas',
                  description: 'Buscar o insertar suele ser rápido cuando el árbol está equilibrado. Si queda inclinado, puede comportarse como una lista.',
                ),
                const SizedBox(height: 24),
                _complexityCards(context, colors),
                const SizedBox(height: 24),
                _callout(
                  context,
                  colors,
                  icon: Icons.copy_all_outlined,
                  text: 'En este laboratorio, los valores repetidos incrementan la frecuencia del mismo nodo y aparecen esa cantidad de veces en los recorridos.',
                ),
              ],
            ),
            _division(
              context,
              colors,
              tone: _BstTone.surface,
              children: [
                _sectionHeading(
                  context,
                  eyebrow: 'PARA SEGUIR APRENDIENDO',
                  title: 'Mira los árboles desde otras perspectivas',
                  description: 'Usa estos videos como apoyo para la explicación, los recorridos y su relación con la teoría de grafos.',
                ),
                const SizedBox(height: 24),
                const VideoResourceCard(
                  title: '¿Qué son y cómo funcionan los árboles? | Ejemplo de implementación',
                  description: 'Introducción visual a las estructuras de árbol y un ejemplo de implementación.',
                  videoUrl: 'https://www.youtube.com/watch?v=tBaOQeyXYqg',
                  durationOrAuthor: 'Árboles binarios',
                ),
                const SizedBox(height: 24),
                const VideoResourceCard(
                  title:
                      'Algoritmos PREORDEN, INORDEN y POSTORDEN en 3 minutos',
                  description: 'Repasa las reglas de visita y compara cómo cambia la secuencia de salida.',
                  videoUrl: 'https://www.youtube.com/watch?v=Jo2euX89Oz8',
                  durationOrAuthor: 'Recorridos de árboles',
                ),
                const SizedBox(height: 24),
                const VideoResourceCard(
                  title: 'Teoría de Grafos',
                  description: 'Serie complementaria para ampliar los conceptos de nodos, conexiones y estructuras relacionadas.',
                  videoUrl: 'https://www.youtube.com/watch?v=O5cDhAhwcHo&list=PLA-D111SLqMQzF_ClAQPqTnVCYrEB323b',
                  durationOrAuthor: 'Lista de reproducción',
                ),
              ],
            ),
            _division(
              context,
              colors,
              tone: _BstTone.high,
              children: [_ctaCard(context, colors)],
            ),
            _footer(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, ColorScheme colors) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bstAccent.withValues(alpha: .25), colors.surface],
        ),
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _bstAccent.withValues(alpha: .4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_tree_rounded,
                        size: 16,
                        color: _bstAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ESTRUCTURAS DE DATOS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _bstAccent,
                          letterSpacing: .4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Árboles binarios de búsqueda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width > 700 ? 42 : 30,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'Organiza datos para encontrarlos siguiendo una regla sencilla: menores a la izquierda, mayores a la derecha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width > 700 ? 18 : 15,
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _openLab(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _bstAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Explorar el laboratorio BST'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _division(
    BuildContext context,
    ColorScheme colors, {
    required _BstTone tone,
    required List<Widget> children,
  }) {
    final bordered = tone != _BstTone.surface;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: switch (tone) {
          _BstTone.surface => colors.surface,
          _BstTone.low => colors.surfaceContainerLow,
          _BstTone.high => colors.surfaceContainerHigh.withValues(alpha: .5),
        },
        border: bordered
            ? Border.symmetric(
                horizontal: BorderSide(
                  color: colors.outline.withValues(alpha: .2),
                  width: 1.5,
                ),
              )
            : null,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _conceptCard(BuildContext context, ColorScheme colors) {
    return Container(
      decoration: _cardDecoration(colors, color: colors.surfaceContainerHigh),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconTile(Icons.hub_outlined, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eyebrow('CONCEPTO CLAVE'),
                    const SizedBox(height: 4),
                    Text(
                      'Un árbol ordenado por decisiones',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 20),
          Text(
            'Un árbol binario conecta cada elemento con una raíz y permite que cada nodo tenga hasta dos hijos. En un árbol binario de búsqueda (BST), la posición de cada clave sigue una regla de orden.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cada comparación descarta una rama completa: si el valor buscado es menor, continúa a la izquierda; si es mayor, sigue a la derecha.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleCards(BuildContext context, ColorScheme colors) {
    final cards = [
      (
        Icons.keyboard_double_arrow_left_rounded,
        'Menor',
        'Va al subárbol izquierdo.',
      ),
      (
        Icons.compare_arrows_rounded,
        'Igual',
        'Incrementa la frecuencia del nodo.',
      ),
      (
        Icons.keyboard_double_arrow_right_rounded,
        'Mayor',
        'Va al subárbol derecho.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((card) {
            final width = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 32) / 3;
            return SizedBox(
              width: width,
              child: _infoCard(
                context,
                colors,
                icon: card.$1,
                title: card.$2,
                body: card.$3,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _treeExampleCard(BuildContext context, ColorScheme colors) {
    return Container(
      decoration: _cardDecoration(colors, color: colors.surfaceContainerLow),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('EJEMPLO'),
          const SizedBox(height: 6),
          Text(
            'La regla se repite en cada subárbol',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El 4 es menor que 5, pero mayor que 3; por eso queda a la derecha del 3.',
            style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Center(child: _ExampleTree()),
        ],
      ),
    );
  }

  Widget _insertionSteps(BuildContext context, ColorScheme colors) {
    final steps = [
      ('4 < 5', 'Ve a la izquierda', Icons.arrow_downward_rounded),
      ('4 > 3', 'Ve a la derecha', Icons.arrow_downward_rounded),
      ('Sin hijo derecho', 'Inserta aquí', Icons.add_circle_outline_rounded),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final cardWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 32) / 3;
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(
                  colors,
                  color: colors.surface,
                  radius: 18,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _bstAccent.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: _bstAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$1,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(step.$3, size: 17, color: _bstAccent),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  step.$2,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _traversalCards(BuildContext context, ColorScheme colors) {
    final data = [
      (
        Icons.vertical_align_top_rounded,
        'Preorder',
        'Raíz → izquierda → derecha',
        '5, 3, 1, 4, 7, 11, 8, 15',
      ),
      (
        Icons.swap_vert_rounded,
        'Inorder',
        'Izquierda → raíz → derecha',
        '1, 3, 4, 5, 7, 8, 11, 15',
      ),
      (
        Icons.vertical_align_bottom_rounded,
        'Postorder',
        'Izquierda → derecha → raíz',
        '1, 4, 3, 8, 15, 11, 7, 5',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: data.map((item) {
            final cardWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 32) / 3;
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: _cardDecoration(colors, color: colors.surface),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconTile(item.$1, size: 24, padding: 9),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: _bstAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: colors.outlineVariant),
                    const SizedBox(height: 12),
                    SelectableText(
                      item.$4,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _complexityCards(BuildContext context, ColorScheme colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final width = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _complexityCard(
              colors,
              width: width,
              title: 'Árbol equilibrado',
              complexity: 'O(log n)',
              body: 'La altura crece de forma gradual; cada comparación descarta buena parte de los nodos.',
              icon: Icons.balance_rounded,
            ),
            _complexityCard(
              colors,
              width: width,
              title: 'Árbol inclinado',
              complexity: 'O(n)',
              body: 'Si los valores llegan casi ordenados, el árbol puede convertirse en una cadena.',
              icon: Icons.show_chart_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _complexityCard(
    ColorScheme colors, {
    required double width,
    required String title,
    required String complexity,
    required String body,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: _cardDecoration(colors, color: colors.surface),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconTile(icon, size: 25),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 3),
                  Text(
                    complexity,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: _bstAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      height: 1.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callout(
    BuildContext context,
    ColorScheme colors, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bstAccent.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bstAccent.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _bstAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(height: 1.5, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaCard(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_bstAccent.withValues(alpha: .18), colors.surface],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: _bstAccent.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 640;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eyebrow('LLEVA LA TEORÍA A LA PRÁCTICA'),
              const SizedBox(height: 8),
              Text(
                'Construye y recorre tu propio árbol',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega valores, reconstruye un BST desde recorridos y observa los resultados en la pizarra.',
                style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: () => _openLab(context),
            style: FilledButton.styleFrom(
              backgroundColor: _bstAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Abrir laboratorio'),
          );
          return stack
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 20), button],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 24),
                    button,
                  ],
                );
        },
      ),
    );
  }

  Widget _footer(BuildContext context, ColorScheme colors) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    color: colors.surface,
    child: Center(
      child: Text(
        'Árboles BST · Estructuras de datos',
        style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
      ),
    ),
  );

  Widget _sectionHeading(
    BuildContext context, {
    required String eyebrow,
    required String title,
    String? description,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(eyebrow),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _eyebrow(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.3,
      color: _bstAccent,
    ),
  );

  Widget _iconTile(IconData icon, {double size = 30, double padding = 12}) =>
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: _bstAccent.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: _bstAccent, size: size),
      );

  Widget _infoCard(
    BuildContext context,
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String body,
  }) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _cardDecoration(colors, color: colors.surfaceContainerLow),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconTile(icon, size: 25, padding: 10),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  BoxDecoration _cardDecoration(
    ColorScheme colors, {
    required Color color,
    double radius = 20,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: colors.outlineVariant.withValues(alpha: .4)),
  );
}

enum _BstTone { surface, low, high }

class _ExampleTree extends StatelessWidget {
  const _ExampleTree();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 700 ? constraints.maxWidth : 700.0;
        return Semantics(
          label: 'Ejemplo BST: raíz 5, hijos 3 y 7; 3 tiene hijos 1 y 4; 7 tiene hijo derecho 11, con hijos 8 y 15.',
          child: SizedBox(
            width: width,
            height: 260,
            child: CustomPaint(
              painter: _ExampleTreePainter(
                line: _bstAccent.withValues(alpha: .65),
                fill: _bstAccent,
                text: Colors.white,
                outline: colors.surface,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExampleTreePainter extends CustomPainter {
  final Color line;
  final Color fill;
  final Color text;
  final Color outline;

  const _ExampleTreePainter({
    required this.line,
    required this.fill,
    required this.text,
    required this.outline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 19.0;
    final points = <int, Offset>{
      5: Offset(size.width * .5, 28),
      3: Offset(size.width * .3, 91),
      7: Offset(size.width * .7, 91),
      1: Offset(size.width * .2, 154),
      4: Offset(size.width * .4, 154),
      11: Offset(size.width * .8, 154),
      8: Offset(size.width * .7, 224),
      15: Offset(size.width * .9, 224),
    };
    for (final (parent, child) in [
      (5, 3),
      (5, 7),
      (3, 1),
      (3, 4),
      (7, 11),
      (11, 8),
      (11, 15),
    ]) {
      final start = points[parent]!;
      final end = points[child]!;
      final vector = end - start;
      final unit = vector / vector.distance;
      canvas.drawLine(
        start + unit * radius,
        end - unit * radius,
        Paint()
          ..color = line
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final entry in points.entries) {
      canvas.drawCircle(entry.value, radius, Paint()..color = fill);
      canvas.drawCircle(
        entry.value,
        radius,
        Paint()
          ..color = outline.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final label = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        entry.value - Offset(label.width / 2, label.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExampleTreePainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.fill != fill ||
      oldDelegate.text != text ||
      oldDelegate.outline != outline;
}
