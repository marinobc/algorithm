import 'package:flutter/material.dart';

class GraphTypesSection extends StatelessWidget {
  const GraphTypesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VARIEDAD DE CONEXIONES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Hacia dónde fluyen los datos?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          // Directed
          _buildGraphTypeRow(
            colorScheme,
            icon: Icons.arrow_forward_rounded,
            color: const Color(0xFF7C4DFF),
            title: 'Grafos Dirigidos (Digrafos)',
            description: 'Las conexiones tienen un sentido único (como una calle de una sola vía o un mensaje de Twitter donde tú sigues a alguien pero no necesariamente te sigue a ti).',
          ),
          const SizedBox(height: 12),
          // Undirected
          _buildGraphTypeRow(
            colorScheme,
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF00BFA5),
            title: 'Grafos No Dirigidos',
            description: 'Las conexiones funcionan en ambos sentidos por igual (como una llamada telefónica o dos amigos en Facebook).',
          ),
        ],
      ),
    );
  }

  Widget _buildGraphTypeRow(
    ColorScheme colorScheme, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
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
