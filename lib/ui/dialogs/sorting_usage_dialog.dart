import 'package:flutter/material.dart';

import '../../domain/services/base_sorting_algorithm.dart';

class SortingUsageDialog extends StatelessWidget {
  final BaseSortingAlgorithm algorithm;

  const SortingUsageDialog({super.key, required this.algorithm});

  static Future<void> show(
    BuildContext context,
    BaseSortingAlgorithm algorithm,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => SortingUsageDialog(algorithm: algorithm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final accent = algorithm.accentColor;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            algorithm.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Guía de uso · ${algorithm.description}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar guía',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        context,
                        number: 1,
                        accent: accent,
                        icon: Icons.edit_note_rounded,
                        title: 'Prepara los datos',
                        body: 'Indica una cantidad mayor que cero y pulsa Continuar. Después escribe todos los valores en Manual y pulsa Visualizar números, o elige Aleatoria y pulsa Generar números.',
                      ),
                      _section(
                        context,
                        number: 2,
                        accent: accent,
                        icon: Icons.view_timeline_outlined,
                        title: 'Sigue el ordenamiento',
                        body: switch (algorithm.id) {
                          'selection' => 'Cada pino representa un valor; su altura indica su magnitud y el número real aparece debajo. i es la posición que se ordena, j el elemento inspeccionado y MIN el menor encontrado. Al terminar la búsqueda, los pinos se intercambian.',
                          'insertion' => 'Cada pino representa un valor; su altura indica su magnitud y el número real aparece debajo. KEY se eleva, j señala el valor comparado y los elementos mayores se desplazan a la derecha antes de insertar la clave.',
                          'shell' => 'Observa h en cada pasada. Los marcadores j y j-h indican posiciones separadas por esa distancia. Si el valor en j es menor, ambos bolos intercambian sus lugares; la última pasada usa h=1.',
                          _ => 'Sigue las dos mitades activas y la fila de fusión. Cada comparación elige el siguiente valor de salida. El proceso se repite hasta fusionar todo el conjunto.',
                        },
                      ),
                      _section(
                        context,
                        number: 3,
                        accent: accent,
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Controla la animación',
                        body: 'Usa Reproducir o Pausar, avanza o retrocede un paso, reinicia y cambia la velocidad entre 0.5x y 4x. La barra de progreso permite ir a cualquier paso. Si hay muchos pinos, arrastra la barra horizontal; durante la reproducción la vista sigue la acción.',
                      ),
                      _section(
                        context,
                        number: 4,
                        accent: accent,
                        icon: Icons.analytics_outlined,
                        title: 'Lee el resultado',
                        body: switch (algorithm.id) {
                          'selection' => 'La franja inferior señala las posiciones ordenadas. El panel derecho muestra comparaciones, intercambios y la complejidad n(n - 1) / 2 ≈ n² / 2, O(n²).',
                          'insertion' => 'La franja inferior señala la región ordenada. El panel derecho muestra comparaciones, desplazamientos, inserciones y la aproximación n² / 4, O(n²).',
                          'shell' => 'El panel muestra h actual, comparaciones e intercambios reales. Al cerrar una pasada, el arreglo queda h-ordenado. Los incrementos de Knuth tienen peor caso Θ(n³ᐟ²).',
                          _ => 'El panel muestra comparaciones y escrituras reales. Merge Sort usa Θ(n log n) tiempo y Θ(n) espacio auxiliar.',
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required int number,
    required Color accent,
    required IconData icon,
    required String title,
    required String body,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
