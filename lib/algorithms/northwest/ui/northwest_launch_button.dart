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
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
