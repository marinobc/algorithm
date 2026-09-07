import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../text/user_guide_text.dart';

typedef TutorialDialog = TutorialScreen;

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[TutorialScreen] Building TutorialScreen widget...');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final guideContent = UserGuideText.markdownContent.trim();
    final bool hasContent = guideContent.isNotEmpty;

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        height: 1.4,
      ),
      h2: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.secondary,
        height: 1.4,
      ),
      h3: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      p: theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
        color: colorScheme.onSurface,
      ),
      code: theme.textTheme.bodyMedium?.copyWith(
        backgroundColor: colorScheme.surfaceContainerHigh,
        color: colorScheme.primary,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colorScheme.primary, width: 4)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Guía de Uso'),
        centerTitle: false,
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: hasContent
          ? SingleChildScrollView(
              key: const ValueKey('tutorial_scroll_view'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: MarkdownBody(
                  key: const ValueKey('tutorial_markdown'),
                  data: guideContent,
                  selectable: true,
                  styleSheet: styleSheet,
                  softLineBreak: true,
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Error: No se pudo cargar el contenido del tutorial.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FilledButton.icon(
                    key: const ValueKey('tutorial_close_btn'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Entendido, volver al lienzo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
