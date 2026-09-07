import 'package:flutter/material.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';

class OverlappingElementItem {
  final String id;
  final String title;
  final String subtitle;
  final bool isNode;
  final IconData icon;
  final Color color;

  const OverlappingElementItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isNode,
    required this.icon,
    required this.color,
  });
}

class OverlappingElementsDialog extends StatelessWidget {
  final List<Nodo> nodes;
  final List<Conexion> connections;
  final Map<String, Nodo> nodeMap;
  final ValueChanged<OverlappingElementItem> onSelected;

  const OverlappingElementsDialog({
    super.key,
    required this.nodes,
    required this.connections,
    required this.nodeMap,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = <OverlappingElementItem>[];

    for (final node in nodes) {
      items.add(
        OverlappingElementItem(
          id: node.id,
          title: node.nombre ?? 'Nodo ${node.id}',
          subtitle: 'Nodo en (${node.x.toInt()}, ${node.y.toInt()})',
          isNode: true,
          icon: Icons.circle_outlined,
          color: Color(node.colorValue),
        ),
      );
    }

    for (final conn in connections) {
      final orig = nodeMap[conn.nodoOrigenId]?.nombre ?? conn.nodoOrigenId;
      final dest = nodeMap[conn.nodoDestinoId]?.nombre ?? conn.nodoDestinoId;
      final isSelfLoop = conn.nodoOrigenId == conn.nodoDestinoId;

      final label = isSelfLoop ? 'Bucle en $orig' : '$orig ➔ $dest';

      items.add(
        OverlappingElementItem(
          id: conn.id,
          title: label,
          subtitle: 'Conexión / Arista',
          isNode: false,
          icon: isSelfLoop ? Icons.loop_rounded : Icons.alt_route_rounded,
          color: Color(conn.colorValue),
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.layers_outlined, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Seleccionar Elemento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hay varios elementos superpuestos en este punto. ¿Cuál deseas editar?',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: colorScheme.surfaceContainerHighest,
                  leading: CircleAvatar(
                    backgroundColor: item.color,
                    radius: 16,
                    child: Icon(item.icon, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(item);
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
