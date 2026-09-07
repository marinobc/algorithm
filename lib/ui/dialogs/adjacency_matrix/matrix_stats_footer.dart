import 'package:flutter/material.dart';

class MatrixStatsFooter extends StatelessWidget {
  final int totalNodes;
  final int totalConnections;
  final int maxDegree;
  final int minDegree;
  final bool hasSelection;
  final VoidCallback onClearSelection;
  final ColorScheme colorScheme;

  const MatrixStatsFooter({
    super.key,
    required this.totalNodes,
    required this.totalConnections,
    required this.maxDegree,
    required this.minDegree,
    required this.hasSelection,
    required this.onClearSelection,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card 1 (Row 1): Nodos Stats
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hub_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Total de Nodos: $totalNodes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Card 2 (Row 2): Conexiones Stats
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alt_route_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Total de Conexiones: $totalConnections',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Card 3 (Row 3): Grado del Grafo (Graph Degree Single Metric)
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Δ(G) = $maxDegree   δ(G) = $minDegree',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (hasSelection)
                  InkWell(
                    onTap: onClearSelection,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Limpiar Selección',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
