import 'package:flutter/material.dart';

class WelcomeBasicsSection extends StatelessWidget {
  const WelcomeBasicsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    final parts = [
      {
        'icon': Icons.input_rounded,
        'title': 'Entrada',
        'text':
            'Los datos iniciales del problema: números, nombres, nodos, costos, tiempos o cualquier información que el algoritmo necesita.',
        'color': const Color(0xFF00BFA5),
      },
      {
        'icon': Icons.settings_suggest_rounded,
        'title': 'Proceso',
        'text':
            'La secuencia de pasos: comparar, ordenar, calcular, validar condiciones y transformar los datos con una lógica definida.',
        'color': const Color(0xFF7C4DFF),
      },
      {
        'icon': Icons.output_rounded,
        'title': 'Salida',
        'text':
            'El resultado final: una ruta, una asignación, una lista ordenada, una decisión o una respuesta que resuelve el problema.',
        'color': const Color(0xFFFF5252),
      },
    ];

    final properties = [
      {
        'icon': Icons.checklist_rounded,
        'title': 'Preciso',
        'text': 'Cada instrucción debe entenderse sin ambigüedad.',
      },
      {
        'icon': Icons.flag_rounded,
        'title': 'Finito',
        'text': 'Debe terminar después de una cantidad limitada de pasos.',
      },
      {
        'icon': Icons.route_rounded,
        'title': 'Ordenado',
        'text': 'Los pasos siguen una secuencia lógica.',
      },
      {
        'icon': Icons.speed_rounded,
        'title': 'Eficiente',
        'text': 'Busca ahorrar tiempo, memoria o esfuerzo.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConceptCard(context, colorScheme),
        const SizedBox(height: 56),
        _buildSectionHeader(
          context,
          badge: 'BASES Y COMPONENTES',
          title: 'Partes y propiedades de un algoritmo',
          subtitle:
              'Identifica qué datos recibe, qué lógica transforma y qué resultado debe entregar.',
        ),
        const SizedBox(height: 28),
        _buildResponsiveInfoGrid(
          context,
          width,
          parts
              .map(
                (item) => _buildInfoCard(
                  context,
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  text: item['text'] as String,
                  accentColor: item['color'] as Color,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildPropertiesStrip(context, colorScheme, properties),
      ],
    );
  }

  Widget _buildConceptCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONCEPTO CLAVE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Qué es un Algoritmo y por qué es fundamental?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Text(
            'Un algoritmo es una secuencia lógica, finita, precisa y ordenada de pasos o instrucciones diseñadas para resolver un problema específico, realizar una tarea bien definida o procesar datos.',
            style: TextStyle(
              fontSize: 17,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'En el mundo moderno, los algoritmos son el motor detrás del software. Permiten que los sistemas informáticos automaticen tareas complejas, tomen decisiones basadas en datos de manera rápida y eficiente, y ahorren recursos valiosos como tiempo y memoria de procesamiento.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String badge,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          badge,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveInfoGrid(
    BuildContext context,
    double width,
    List<Widget> children,
  ) {
    if (width < 760) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 18),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    required Color accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 25),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesStrip(
    BuildContext context,
    ColorScheme colorScheme,
    List<Map<String, Object>> properties,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 900
              ? 4
              : width >= 560
                  ? 2
                  : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 104,
            ),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final item = properties[index];
              return _buildPropertyPill(
                context,
                icon: item['icon'] as IconData,
                title: item['title'] as String,
                text: item['text'] as String,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPropertyPill(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
