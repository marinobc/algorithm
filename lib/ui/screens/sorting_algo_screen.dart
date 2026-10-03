import 'package:flutter/material.dart';

import '../../domain/services/sorting_steps.dart';
import '../widgets/sorting_pin_visualizer.dart';
import '../widgets/web_explanation_navbar.dart';
import 'sorting_visualizer_screen.dart';

class SortingAlgoScreen extends StatelessWidget {
  final SortingAlgorithm algorithm;

  const SortingAlgoScreen({super.key, required this.algorithm});

  bool get _selection => algorithm == SortingAlgorithm.selection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = _selection ? 'Selection Sort' : 'Insertion Sort';
    final accent = _selection
        ? const Color(0xFFFF9100)
        : const Color(0xFF00BFA5);
    final example = _selection ? [8, 3, 6, 2] : [3, 7, 4, 9];
    final initial = SortingTimeline.build(algorithm, example).steps.first;

    return WebExplanationShell(
      activePage: _selection
          ? ExplanationWebPage.selectionSort
          : ExplanationWebPage.insertionSort,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selection
                              ? Icons.sort_rounded
                              : Icons.low_priority_rounded,
                          color: accent,
                          size: 26,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: MediaQuery.sizeOf(context).width > 700
                                ? 42
                                : 30,
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Text(
                            _selection
                                ? 'Encuentra el menor elemento del tramo pendiente y colócalo en su posición definitiva.'
                                : 'Toma cada elemento y ubícalo en el lugar correcto dentro de la parte ya ordenada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _launchButton(context, title),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _section(
              context,
              children: [
                _heading(context, '¿Cómo funciona?'),
                const SizedBox(height: 12),
                Text(
                  _selection
                      ? 'Selection Sort divide el arreglo en una parte ordenada y otra pendiente. En cada recorrido busca el valor mínimo de la parte pendiente y lo intercambia con el primer elemento de esa parte.'
                      : 'Insertion Sort construye una región ordenada de izquierda a derecha. Extrae el elemento actual, desplaza a la derecha los valores mayores y lo inserta en el espacio que queda.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 270,
                  child: SortingPinVisualizer(
                    values: example,
                    previous: initial,
                    current: initial,
                    progress: const AlwaysStoppedAnimation<double>(1),
                  ),
                ),
              ],
            ),
            _section(
              context,
              alternate: true,
              children: [
                _heading(context, 'Paso a paso'),
                const SizedBox(height: 20),
                ...(_selection
                        ? [
                            (
                              '1. Elige una posición',
                              'Comienza por el primer lugar que todavía no está ordenado.',
                            ),
                            (
                              '2. Busca el mínimo',
                              'Compara todos los elementos restantes y conserva el menor encontrado.',
                            ),
                            (
                              '3. Intercambia',
                              'Mueve el mínimo a la posición elegida. Repite con la siguiente posición.',
                            ),
                          ]
                        : [
                            (
                              '1. Extrae la clave',
                              'Toma el siguiente elemento a la derecha de la región ordenada.',
                            ),
                            (
                              '2. Desplaza',
                              'Compara hacia la izquierda y mueve una posición a la derecha cada valor mayor.',
                            ),
                            (
                              '3. Inserta',
                              'Coloca la clave en el espacio libre y amplía la región ordenada.',
                            ),
                          ])
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: accent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.$1,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step.$2,
                                    style: TextStyle(
                                      fontSize: 15,
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
                    ),
                const SizedBox(height: 10),
                Text(
                  _selection
                      ? 'Ejemplo: [8, 3, 6, 2] → el mínimo es 2 → se intercambia con 8 → [2, 3, 6, 8].'
                      : 'Ejemplo: [3, 7, 4, 9] → la clave es 4 → 7 se desplaza → [3, 4, 7, 9].',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            _section(
              context,
              children: [
                _heading(context, 'Complejidad'),
                const SizedBox(height: 12),
                Text(
                  _selection ? 'n(n - 1) / 2 ≈ n² / 2' : 'n² / 4',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selection
                      ? 'Realiza n(n - 1) / 2 comparaciones, incluso si los datos ya estaban ordenados. Complejidad temporal: O(n²).'
                      : 'La aproximación utilizada en la materia es n² / 4. El trabajo depende del orden inicial de los datos; su complejidad temporal es O(n²).',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _launchButton(context, title),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required List<Widget> children,
    bool alternate = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: alternate ? colors.surfaceContainerLow : colors.surface,
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

  Widget _heading(BuildContext context, String title) => Text(
    title,
    style: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );

  Widget _launchButton(BuildContext context, String title) =>
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SortingVisualizerScreen(algorithm: algorithm),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text('Probar $title'),
      );
}
