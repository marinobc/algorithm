import 'package:flutter/material.dart';

import '../../../../ui/widgets/math_rich_text.dart';

class NorthwestTheorySections {
  static const Color accentColor = Color(0xFFE54872);

  static Widget buildConceptCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué es la Esquina Noroeste?',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Es un algoritmo heurístico de programación lineal diseñado para encontrar una Solución Básica Factible (SBF) inicial en problemas de transporte. Asigna la máxima cantidad posible a la casilla superior izquierda (noroeste) ajustando oferta y demanda de forma iterativa.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildLearningSection(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildMathFormulationCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions_rounded, color: accentColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'Formulación Matemática de Transporte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MathRichText(
            text: r'$$\min Z = \sum_{i=1}^{m} \sum_{j=1}^{n} c_{ij} x_{ij}$$',
            mathColor: accentColor,
            mathBgColor: accentColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sujeto a restricciones de Oferta y Demanda:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              MathRichText(
                text: r'$\sum_{j=1}^{n} x_{ij} \le a_i \quad \forall i$',
                mathColor: colorScheme.primary,
              ),
              MathRichText(
                text: r'$\sum_{i=1}^{m} x_{ij} \ge b_j \quad \forall j$',
                mathColor: colorScheme.primary,
              ),
              MathRichText(
                text: r'$x_{ij} \ge 0$',
                mathColor: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildModelSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final items = [
      (
        'Orígenes (Oferta)',
        'Fábricas, almacenes o centros de acopio con cantidad disponible de bienes.',
        Icons.inventory_2_outlined,
      ),
      (
        'Destinos (Demanda)',
        'Tiendas, distribuidores o clientes con requerimientos específicos.',
        Icons.flag_outlined,
      ),
      (
        'Costos de Flete',
        'Costo unitario por transportar bienes de cada origen a cada destino.',
        Icons.attach_money_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ELEMENTOS DEL MODELO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Estructura de la Matriz de Transporte',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cada fila representa un punto de origen y cada columna un punto de destino. Las celdas guardan el costo unitario de transporte.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 142,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$3, color: accentColor, size: 26),
                      const SizedBox(height: 9),
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  static Widget buildMethodsSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final methods = [
      (
        'Esquina Noroeste',
        'Método sistemático inicial. No analiza costos pero genera una solución básica factible rápidamente.',
        Icons.grid_view_rounded,
      ),
      (
        'Costo Mínimo',
        'Prioriza celdas con menor tarifa de flete para obtener una solución inicial más económica.',
        Icons.savings_outlined,
      ),
      (
        'Método MODI (u-v)',
        'Calcula multiplicadores para evaluar celdas vacías y reajustar envíos hasta el óptimo global.',
        Icons.auto_graph_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MÉTODOS DE SOLUCIÓN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fases para Resolver Transporte',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: methods.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 174,
              ),
              itemBuilder: (context, index) {
                final method = methods[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(method.$3, color: accentColor, size: 26),
                      const SizedBox(height: 9),
                      Text(
                        method.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          method.$2,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
