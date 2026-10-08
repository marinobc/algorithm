import 'package:flutter/material.dart';

import '../dialogs/algorithm_selection_dialog.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'graph_editor_screen.dart';
import 'widgets/welcome/welcome_basics_section.dart';
import 'widgets/welcome/welcome_examples_grid.dart';
import 'widgets/welcome/welcome_footer_section.dart';
import 'widgets/welcome/welcome_hero_section.dart';

class WelcomeExplanationScreen extends StatefulWidget {
  const WelcomeExplanationScreen({super.key});

  @override
  State<WelcomeExplanationScreen> createState() =>
      _WelcomeExplanationScreenState();
}

class _WelcomeExplanationScreenState extends State<WelcomeExplanationScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _examplesKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToLibrary(BuildContext context) async {
    final didSelect = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AlgorithmSelectionScreen()),
    );
    if (didSelect != false && didSelect != null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
      );
    }
  }

  void _scrollToExamples() {
    final context = _examplesKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return WebExplanationShell(
      activePage: ExplanationWebPage.algorithms,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section Banner
            WelcomeHeroSection(
              onOpenEditor: () => _navigateToLibrary(context),
              onScrollToExamples: _scrollToExamples,
            ),

            // Main Content Area
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 48.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WelcomeBasicsSection(),

                      const SizedBox(height: 56),

                      // Interactive Videos Section Header
                      _buildSectionHeader(
                        context,
                        badge: 'MATERIAL AUDIOVISUAL',
                        title: 'Videos Explicativos Recomendados',
                        subtitle: 'Dos explicaciones introductorias para conectar la teoría con ejemplos y procesos paso a paso.',
                      ),
                      const SizedBox(height: 28),
                      _buildVideosSection(context, screenWidth),

                      const SizedBox(height: 56),

                      // Examples Title Section
                      Container(
                        key: _examplesKey,
                        child: _buildSectionHeader(
                          context,
                          badge: 'APLICACIONES EN EL MUNDO REAL',
                          title: '3 Ejemplos Prácticos de Algoritmos',
                          subtitle: 'Descubre cómo la lógica algorítmica resuelve problemas cotidianos a gran escala.',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Examples Grid
                      const WelcomeExamplesGrid(),

                      const SizedBox(height: 60),

                      // Call to Action Web Banner
                      _buildCallToActionWebCard(context, colorScheme),
                    ],
                  ),
                ),
              ),
            ),

            // Web Footer
            WelcomeFooterSection(
              onOpenEditor: () => _navigateToLibrary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection(BuildContext context, double width) {
    const videos = [
      VideoResourceCard(
        title: 'Introducción visual a los algoritmos',
        description: 'Un recurso de apoyo para entender cómo una serie de instrucciones ordenadas permite resolver problemas de forma clara y repetible.',
        videoUrl: 'https://www.youtube.com/watch?v=U3CGMyjzlvM',
        durationOrAuthor: 'Video introductorio',
      ),
      VideoResourceCard(
        title: 'Algoritmos explicados paso a paso',
        description: 'Material complementario para repasar conceptos básicos, ejemplos y la lógica detrás de la resolución estructurada de problemas.',
        videoUrl: 'https://www.youtube.com/watch?v=FS9u9cIGf3o&list=PLYYyYpMvAtD1Gu8o1734Ld22LTDxlfKfO',
        durationOrAuthor: 'Lista de reproducción',
      ),
    ];

    if (width < 760) {
      return Column(
        children: [videos[0], const SizedBox(height: 20), videos[1]],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: videos[0]),
        const SizedBox(width: 24),
        Expanded(child: videos[1]),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String badge,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          badge,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCallToActionWebCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.hub_outlined, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            '¿Listo para poner a prueba estos conceptos?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Accede a la biblioteca interactiva para crear, editar y visualizar grafos en tiempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToLibrary(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            label: const Text(
              'Ir a la Aplicación Principal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
