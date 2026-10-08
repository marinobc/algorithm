import 'package:flutter/material.dart';

import '../../domain/services/sorting_steps.dart';

class SortingUsageDialog extends StatelessWidget {
  final SortingAlgorithm algorithm;

  const SortingUsageDialog({super.key, required this.algorithm});

  static Future<void> show(BuildContext context, SortingAlgorithm algorithm) {
    return showDialog<void>(
      context: context,
      builder: (_) => SortingUsageDialog(algorithm: algorithm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSelection = algorithm == SortingAlgorithm.selection;
    final title = isSelection ? 'Selection Sort' : 'Insertion Sort';
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía de uso',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          title,
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
              const Divider(height: 28),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        context,
                        icon: Icons.edit_note_rounded,
                        title: '1. Prepara los datos',
                        body: 'Indica entre 1 y 60 elementos y pulsa Continuar. Después escribe todos los valores en Manual y pulsa Visualizar números, o elige Aleatoria y pulsa Generar números.',
                      ),
                      _section(
                        context,
                        icon: Icons.view_timeline_outlined,
                        title: '2. Sigue el ordenamiento',
                        body: isSelection
                            ? 'Cada pino representa un valor; su altura indica su magnitud y el número real aparece debajo. i es la posición que se ordena, j el elemento inspeccionado y MIN el menor encontrado. Al terminar la búsqueda, los pinos se intercambian.'
                            : 'Cada pino representa un valor; su altura indica su magnitud y el número real aparece debajo. KEY se eleva, j señala el valor comparado y los elementos mayores se desplazan a la derecha antes de insertar la clave.',
                      ),
                      _section(
                        context,
                        icon: Icons.play_circle_outline_rounded,
                        title: '3. Controla la animación',
                        body: 'Usa Reproducir o Pausar, avanza o retrocede un paso, reinicia y cambia la velocidad entre 0.5x y 4x. La barra de progreso permite ir a cualquier paso. Si hay muchos pinos, arrastra la barra horizontal; durante la reproducción la vista sigue la acción.',
                      ),
                      _section(
                        context,
                        icon: Icons.analytics_outlined,
                        title: '4. Lee el resultado',
                        body: isSelection
                            ? 'La franja inferior señala las posiciones ordenadas. El panel derecho muestra comparaciones, intercambios y la complejidad n(n - 1) / 2 ≈ n² / 2, O(n²).'
                            : 'La franja inferior señala la región ordenada. El panel derecho muestra comparaciones, desplazamientos, inserciones y la aproximación n² / 4, O(n²).',
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
    required IconData icon,
    required String title,
    required String body,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: colors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
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
