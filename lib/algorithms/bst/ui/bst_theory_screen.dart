import 'package:flutter/material.dart';

import '../../../ui/widgets/web_explanation_navbar.dart';
import 'bst_lab_screen.dart';

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
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: colors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTRUCTURAS DE DATOS',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Árboles binarios de búsqueda',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Una estructura de decisiones que permite encontrar, insertar y recorrer valores siguiendo una regla sencilla.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _openLab(context),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Probar árboles BST'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _band(
              context,
              children: [
                _heading(context, '¿Qué es un árbol binario?'),
                _body(
                  context,
                  'Es una estructura de nodos conectados desde una raíz. Cada nodo puede tener, como máximo, un hijo izquierdo y uno derecho. Los nodos sin hijos se llaman hojas.',
                ),
                const SizedBox(height: 28),
                _heading(context, '¿Cuándo es un BST?'),
                _body(
                  context,
                  'En un árbol binario de búsqueda (BST), todas las claves del subárbol izquierdo son menores que la clave del nodo; todas las del derecho son mayores. Esta regla se cumple en cada subárbol, no solo junto a la raíz.',
                ),
                const SizedBox(height: 28),
                const _ExampleTree(),
              ],
            ),
            _band(
              context,
              alternate: true,
              children: [
                _heading(context, 'Construcción paso a paso'),
                _body(
                  context,
                  'Inserta 5, 3, 7, 1, 4, 11, 8, 15. El 5 será la raíz; el 3 irá a su izquierda y el 7 a su derecha. Para ubicar el 4, compáralo con 5 (menor) y después con 3 (mayor): termina como hijo derecho de 3.',
                ),
                const SizedBox(height: 20),
                _body(
                  context,
                  'Los duplicados permanecen en el mismo nodo mediante un contador ×N. Así se conserva la regla estricta de izquierda menor y derecha mayor. Un BST no se balancea automáticamente: el orden de inserción puede producir un árbol alto.',
                ),
              ],
            ),
            _band(
              context,
              children: [
                _heading(context, 'Tres formas de recorrer el árbol'),
                _body(
                  context,
                  'Cada recorrido visita los mismos valores en otro orden. En el ejemplo, Inorder devuelve las claves ordenadas.',
                ),
                const SizedBox(height: 22),
                _traversal(
                  context,
                  'Preorder',
                  'Raíz → izquierda → derecha',
                  '5, 3, 1, 4, 7, 11, 8, 15',
                ),
                _traversal(
                  context,
                  'Inorder',
                  'Izquierda → raíz → derecha',
                  '1, 3, 4, 5, 7, 8, 11, 15',
                ),
                _traversal(
                  context,
                  'Postorder',
                  'Izquierda → derecha → raíz',
                  '1, 4, 3, 8, 15, 11, 7, 5',
                ),
              ],
            ),
            _band(
              context,
              alternate: true,
              children: [
                _heading(context, 'Explóralo en el laboratorio'),
                _body(
                  context,
                  'Construye un BST valor por valor, genera datos aleatorios o reconstruye el árbol desde dos recorridos compatibles. La pizarra y los tres resultados se actualizan a partir del mismo árbol.',
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => _openLab(context),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Abrir laboratorio BST'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _band(
    BuildContext context, {
    required List<Widget> children,
    bool alternate = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: alternate ? colors.surfaceContainerLow : colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _body(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _traversal(
    BuildContext context,
    String name,
    String rule,
    String values,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route_outlined, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · $rule',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(values, style: TextStyle(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleTree extends StatelessWidget {
  const _ExampleTree();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620 ? constraints.maxWidth : 620.0;
        return Semantics(
          label: 'Ejemplo BST: raíz 5, hijos 3 y 7; 3 tiene hijos 1 y 4; 7 tiene hijo derecho 11, con hijos 8 y 15.',
          child: SizedBox(
            width: width,
            height: 230,
            child: CustomPaint(
              painter: _ExampleTreePainter(
                line: colors.outline,
                fill: colors.primaryContainer,
                text: colors.onPrimaryContainer,
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

  const _ExampleTreePainter({
    required this.line,
    required this.fill,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = <int, Offset>{
      5: Offset(size.width * .5, 30),
      3: Offset(size.width * .3, 90),
      7: Offset(size.width * .7, 90),
      1: Offset(size.width * .2, 150),
      4: Offset(size.width * .4, 150),
      11: Offset(size.width * .8, 150),
      8: Offset(size.width * .7, 205),
      15: Offset(size.width * .9, 205),
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
      canvas.drawLine(
        points[parent]!,
        points[child]!,
        Paint()
          ..color = line
          ..strokeWidth = 2,
      );
    }
    for (final entry in points.entries) {
      canvas.drawCircle(entry.value, 17, Paint()..color = fill);
      final label = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.bold,
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
      oldDelegate.text != text;
}
