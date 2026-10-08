import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/screens/graph_editor_screen.dart';
import '../../core/algorithm_registry.dart';

/// Dedicated launch button for the Assignment Algorithm to be embedded
/// in the explanation webpage or tutorials.
class AssignmentLaunchButton extends ConsumerWidget {
  final String label;
  final IconData icon;

  const AssignmentLaunchButton({
    super.key,
    this.label = 'Dibujar Grafo de Asignación',
    this.icon = Icons.assignment_turned_in_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accentColor = Color(0xFF7C4DFF);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ElevatedButton.icon(
      onPressed: () {
        // Select Assignment Algorithm in Riverpod
        ref
            .read(activeAlgorithmProvider.notifier)
            .selectById(AlgorithmRegistry.assignmentId);

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
