import 'package:flutter/material.dart';

/// A modular, reusable floating card shell for graph algorithm overlays.
///
/// Features a standardized header (icon, title, custom header actions, minimize button, close button),
/// optional summary result banner, and custom content body (e.g. chips, steps, or info).
class BaseAlgorithmCard extends StatefulWidget {
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
  State<BaseAlgorithmCard> createState() => _BaseAlgorithmCardState();
}

class _BaseAlgorithmCardState extends State<BaseAlgorithmCard> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized Header Row
            Row(
              children: [
                Icon(widget.icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_isMinimized && widget.headerActions != null) ...[
                  ...widget.headerActions!,
                  const SizedBox(width: 4),
                ],
                // Minimize / Expand Toggle Button
                IconButton(
                  icon: Icon(
                    _isMinimized
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 20,
                  ),
                  tooltip: _isMinimized ? 'Expandir' : 'Minimizar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _isMinimized = !_isMinimized;
                    });
                  },
                ),
                // Close / Deactivate Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Salir del Algoritmo',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),

            if (!_isMinimized) ...[
              // Optional Result Banner (e.g., Z = 150)
              if (widget.resultBanner != null) ...[
                const SizedBox(height: 6),
                widget.resultBanner!,
              ],

              // Optional Custom Content Body (e.g., assignment chips or path nodes)
              if (widget.body != null) ...[
                const SizedBox(height: 6),
                widget.body!,
              ],
            ],
          ],
        ),
      ),
    );
  }
}
