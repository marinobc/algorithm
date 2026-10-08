import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/screens/graph_editor_screen.dart';
import '../../core/algorithm_registry.dart';

/// Dedicated launch button for the Northwest Algorithm to be embedded
/// in the explanation webpage or tutorials.
class NorthwestLaunchButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const NorthwestLaunchButton({
    super.key,
    this.label = 'Dibujar Grafo de Northwest',
    this.icon = Icons.grid_view_rounded,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accentColor = Color(0xFFE54872);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ElevatedButton.icon(
      onPressed:
          onPressed ??
          () {
            // Select Northwest Algorithm in Riverpod
            ref
                .read(activeAlgorithmProvider.notifier)
                .selectById(AlgorithmRegistry.northwestId);

            // Navigate to the canvas editor
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
            );
          },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 3,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 26,
          vertical: isMobile ? 12 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: isMobile ? 18 : 20),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 13 : 14,
        ),
      ),
    );
  }
}
