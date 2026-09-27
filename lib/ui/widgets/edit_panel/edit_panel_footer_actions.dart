import 'package:flutter/material.dart';

import '../../text/app_text.dart';

class EditPanelFooterActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const EditPanelFooterActions({
    super.key,
    required this.onDelete,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Eliminar',
          onPressed: onDelete,
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: onCancel,
              child: const Text(AppText.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSave,
              child: const Text(AppText.save),
            ),
          ],
        ),
      ],
    );
  }
}
