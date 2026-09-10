import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ColorScheme colorScheme;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText:
                  'Consulta la matriz, guía o pide crear/modificar el grafo...',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.send_rounded),
          onPressed: onSend,
        ),
      ],
    );
  }
}
