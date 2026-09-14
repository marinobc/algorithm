import 'package:flutter/material.dart';

import '../../../domain/services/graph_storage_service.dart';
import '../graph_thumbnail_widget.dart';

class GraphCardWidget extends StatelessWidget {
  final SavedGraphItem item;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onOpenMatrix;
  final VoidCallback onDelete;

  const GraphCardWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRename,
    required this.onOpenMatrix,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBgColor = colorScheme.surfaceContainerLow;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardBgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GraphThumbnailWidget(
                  item: item,
                  backgroundColor: cardBgColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          tooltip: 'Editar nombre del grafo',
                          icon: Icon(
                            Icons.edit_rounded,
                            color: colorScheme.outline,
                          ),
                          onPressed: onRename,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Ver Matriz de Adyacencia',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                        ),
                        icon: const Icon(Icons.grid_on_rounded, size: 18),
                        onPressed: onOpenMatrix,
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Eliminar Grafo',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatBadge(
                    icon: Icons.circle,
                    label: 'N:${item.nodoCount}',
                    bg: colorScheme.primaryContainer,
                    fg: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  _StatBadge(
                    icon: Icons.alt_route_rounded,
                    label: 'A:${item.conexionCount}',
                    bg: colorScheme.secondaryContainer,
                    fg: colorScheme.onSecondaryContainer,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      item.fecha,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
