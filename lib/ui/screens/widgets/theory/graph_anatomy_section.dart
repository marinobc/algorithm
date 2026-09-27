import 'package:flutter/material.dart';

class GraphAnatomySection extends StatelessWidget {
  const GraphAnatomySection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ELEMENTOS PRINCIPALES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Anatomía Básica de un Grafo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildAnatomyCard(
                    context,
                    title: '1. Nodos o Vértices',
                    icon: Icons.circle_outlined,
                    color: const Color(0xFF7C4DFF),
                    description: 'Son las entidades individuales de la red que guardan datos como su nombre o estado.',
                  ),
                ),
                SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildAnatomyCard(
                    context,
                    title: '2. Aristas o Enlaces',
                    icon: Icons.alt_route_rounded,
                    color: const Color(0xFF00BFA5),
                    description: 'Son los enlaces que indican interacción o posibilidad de viaje de un nodo a otro.',
                  ),
                ),
                SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildAnatomyCard(
                    context,
                    title: '3. Pesos o Costos',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFFFF5252),
                    description: 'Es el "costo", la distancia o el tiempo que toma atravesar esa conexión concreta.',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnatomyCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20.0),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
