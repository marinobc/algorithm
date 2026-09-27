import 'package:flutter/material.dart';

class EditPanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const EditPanelHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
