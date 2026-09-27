import 'package:flutter/material.dart';

import '../../widgets/floating_context_menu.dart';

class CanvasContextMenuOverlay extends StatelessWidget {
  final Offset position;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const CanvasContextMenuOverlay({
    super.key,
    required this.position,
    required this.onEdit,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: (position.dx).clamp(0.0, screenSize.width - 150),
      top: (position.dy).clamp(0.0, screenSize.height - 120),
      child: FloatingContextMenu(
        onEdit: onEdit,
        onDelete: onDelete,
        onDismiss: onDismiss,
      ),
    );
  }
}
