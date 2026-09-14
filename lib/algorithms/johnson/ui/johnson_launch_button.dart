import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/screens/graph_editor_screen.dart';
import '../../core/algorithm_registry.dart';

/// Dedicated launch button for the Johnson / CPM Algorithm to be embedded
/// in the explanation webpage or tutorials.
class JohnsonLaunchButton extends ConsumerWidget {
  final String label;
  final IconData icon;

  const JohnsonLaunchButton({
    super.key,
    this.label = 'Dibujar Grafo de Johnson / CPM',
    this.icon = Icons.alt_route_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accentColor = Color(0xFF00BFA5);

    return ElevatedButton.icon(
      onPressed: () {
        // Select Johnson Algorithm in Riverpod
        ref
            .read(activeAlgorithmProvider.notifier)
            .selectById(AlgorithmRegistry.johnsonId);

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
