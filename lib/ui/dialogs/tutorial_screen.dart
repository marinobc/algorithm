import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../text/user_guide_text.dart';

typedef TutorialDialog = TutorialScreen;

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _selectedTab = 0; // 0: Algorithm Guide (if active), 1: General Guide

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeAlgo = ref.watch(activeAlgorithmProvider);

    final String algorithmGuide = activeAlgo?.userGuideMarkdown.trim() ?? '';
    final String generalGuide = UserGuideText.markdownContent.trim();

    final bool hasActiveAlgo = activeAlgo != null && algorithmGuide.isNotEmpty;
    final String currentContent = (hasActiveAlgo && _selectedTab == 0)
        ? algorithmGuide
        : generalGuide;

    final bool hasContent = currentContent.isNotEmpty;
    final accent = hasActiveAlgo && _selectedTab == 0
        ? activeAlgo.themeColor
        : colorScheme.primary;
    final sections = currentContent.split(RegExp(r'\n---\s*\n'));
    final introduction = sections.first.replaceFirst(
      RegExp(r'^# [^\n]+\n*'),
      '',
    );

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: accent,
        height: 1.4,
      ),
      h2: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: accent,
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
        color: accent,
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
        border: Border(left: BorderSide(color: accent, width: 4)),
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
        title: Text(
          hasActiveAlgo && _selectedTab == 0
              ? 'Guía de Uso: ${activeAlgo.name}'
              : 'Guía de Uso General',
        ),
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
      body: Column(
        children: [
          if (hasActiveAlgo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Center(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(activeAlgo.icon, size: 18),
                      label: Text('Guía ${activeAlgo.shortName}'),
                    ),
                    const ButtonSegment<int>(
                      value: 1,
                      icon: Icon(Icons.menu_book_rounded, size: 18),
                      label: Text('Guía General App'),
                    ),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedTab = newSelection.first;
                    });
                  },
                ),
              ),
            ),
          Expanded(
            child: hasContent
                ? SingleChildScrollView(
                    key: const ValueKey('tutorial_scroll_view'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    hasActiveAlgo && _selectedTab == 0
                                        ? activeAlgo.icon
                                        : Icons.menu_book_rounded,
                                    color: accent,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasActiveAlgo && _selectedTab == 0
                                              ? activeAlgo.name
                                              : 'Editor de grafos',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        MarkdownBody(
                                          key: const ValueKey(
                                            'tutorial_markdown',
                                          ),
                                          data: introduction,
                                          selectable: true,
                                          styleSheet: styleSheet,
                                          softLineBreak: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (
                              var index = 1;
                              index < sections.length;
                              index++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          index.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: MarkdownBody(
                                          data: sections[index].trim(),
                                          selectable: true,
                                          styleSheet: styleSheet,
                                          softLineBreak: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
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
          ),
        ],
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
