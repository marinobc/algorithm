import 'package:flutter/material.dart';

/// A modular, reusable floating card shell for graph algorithm overlays.
///
/// Features a standardized header (icon, title, custom header actions, close button),
/// optional summary result banner, and custom content body (e.g. chips, steps, or info).
class BaseAlgorithmCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? headerActions;
  final VoidCallback onClose;
  final Widget? resultBanner;
  final Widget? body;

  const BaseAlgorithmCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onClose,
    this.headerActions,
    this.resultBanner,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized Header Row
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (headerActions != null) ...[
                  ...headerActions!,
                  const SizedBox(width: 4),
                ],
                // Close / Deactivate Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Salir del Algoritmo',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onClose,
                ),
              ],
            ),

            // Optional Result Banner (e.g., Z = 150)
            if (resultBanner != null) ...[
              const SizedBox(height: 8),
              resultBanner!,
            ],

            // Optional Custom Content Body (e.g., assignment chips or path nodes)
            if (body != null) ...[
              const SizedBox(height: 8),
              body!,
            ],
          ],
        ),
      ),
    );
  }
}
