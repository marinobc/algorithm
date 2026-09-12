import 'package:flutter/material.dart';

export 'table_import_dialog.dart';

enum NewGraphMode { visualDesign, adjacencyMatrix }

Future<NewGraphMode?> showNewGraphModeDialog(BuildContext context) {
  return showDialog<NewGraphMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Crear nuevo grafo'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeTile(
              icon: Icons.gesture_rounded,
              title: 'Diseño visual',
              subtitle: 'Crea y conecta nodos directamente en el lienzo.',
              onTap: () => Navigator.pop(context, NewGraphMode.visualDesign),
            ),
            const SizedBox(height: 12),
            _ModeTile(
              icon: Icons.table_chart_outlined,
              title: 'Construcción desde tabla',
              subtitle: 'Define una matriz y genera automáticamente el grafo.',
              onTap: () => Navigator.pop(context, NewGraphMode.adjacencyMatrix),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
