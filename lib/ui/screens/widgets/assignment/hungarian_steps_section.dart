import 'package:flutter/material.dart';

class HungarianStepsSection extends StatelessWidget {
  const HungarianStepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    final steps = [
      {
        'step': 'Paso 1',
        'title': 'Reducción por Filas',
        'desc': 'Resta el menor número de cada fila a todos los elementos de esa fila. ¡Ahora cada fila tiene al menos un cero!',
      },
      {
        'step': 'Paso 2',
        'title': 'Reducción por Columnas',
        'desc': 'Resta el menor número de cada columna a todas sus celdas para multiplicar los ceros disponibles en la tabla.',
      },
      {
        'step': 'Paso 3',
        'title': 'Cubrir Ceros con Líneas',
        'desc': 'Trazas el mínimo número de líneas (horizontales o verticales) para tachar todos los ceros existentes.',
      },
      {
        'step': 'Paso 4',
        'title': 'Asignar Parejas Óptimas',
        'desc': 'Cuando las líneas son iguales al número de filas, seleccionas las casillas con ceros para emparejar cada recurso a su tarea.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENERACIÓN Y SELECCIÓN DE CEROS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF7C4DFF),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pasos Sencillos del Algoritmo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width >= 800 ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 200,
          ),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final item = steps[index];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['step']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title']!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      item['desc']!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
