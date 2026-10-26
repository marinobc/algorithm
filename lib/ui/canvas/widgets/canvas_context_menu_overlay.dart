import 'package:flutter/material.dart';

import '../../widgets/floating_context_menu.dart';

class CanvasContextMenuOverlay extends StatelessWidget {
  final Offset position;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;
  final List<CanvasContextAction> actions;

  const CanvasContextMenuOverlay({
    super.key,
    required this.position,
    required this.onEdit,
    required this.onDelete,
    required this.onDismiss,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: (position.dx).clamp(
        0.0,
        screenSize.width - (actions.isEmpty ? 150 : 220),
      ),
      top: (position.dy).clamp(
        0.0,
        screenSize.height - (actions.isEmpty ? 120 : 220),
      ),
      child: FloatingContextMenu(
        onEdit: onEdit,
        onDelete: onDelete,
        onDismiss: onDismiss,
        actions: actions,
      ),
    );
  }
}
