import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: isUser
            ? Text(
                text,
                style: TextStyle(color: colorScheme.onPrimary, fontSize: 13),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
      ),
    );
  }
}
