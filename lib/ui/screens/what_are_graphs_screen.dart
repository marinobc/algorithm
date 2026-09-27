import 'package:flutter/material.dart';

import '../dialogs/algorithm_selection_dialog.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'graph_editor_screen.dart';
import 'widgets/theory/graph_anatomy_section.dart';
import 'widgets/theory/graph_applications_section.dart';
import 'widgets/theory/graph_theory_hero_section.dart';
import 'widgets/theory/graph_types_section.dart';

class WhatAreGraphsScreen extends StatelessWidget {
  const WhatAreGraphsScreen({super.key});

  Future<void> _navigateToLibrary(BuildContext context) async {
    final didSelect = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AlgorithmSelectionScreen()),
    );
    if (didSelect == true && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WebExplanationShell(
      activePage: ExplanationWebPage.graphs,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section
            GraphTheoryHeroSection(
              onOpenEditor: () => _navigateToLibrary(context),
            ),

            // Main Content Box
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Definition Card
                      _buildDefinitionCard(context, colorScheme),
                      const SizedBox(height: 36),

                      // 2. Video Support Card
                      const VideoResourceCard(
                        title: 'Video recomendado: Introducción a los grafos',
                        description:
                            'Aprende de forma visual con ejemplos interactivos qué son los nodos y las conexiones.',
                        videoUrl: 'https://www.youtube.com/watch?v=vnNFiNVy9KM',
                        durationOrAuthor: 'Explicación en Video',
                      ),
                      const SizedBox(height: 20),
                      const VideoResourceCard(
                        title: 'Video recomendado: conceptos fundamentales',
                        description:
                            'Refuerza la diferencia entre vértices, aristas y las relaciones que modelan.',
                        videoUrl: 'https://www.youtube.com/watch?v=F5Xjpg0-NhM',
                        durationOrAuthor: 'Teoría de Grafos',
                      ),

                      const SizedBox(height: 56),

                      // 3. Anatomy Section
                      const GraphAnatomySection(),
                      const SizedBox(height: 48),

                      // 3.1 Graph Types (Directed vs Undirected)
                      const GraphTypesSection(),

                      const SizedBox(height: 56),

                      // 4. Practical Applications & Vocabulary
                      const GraphApplicationsSection(),
                      const SizedBox(height: 48),
                      _buildGraphVocabularySection(context, colorScheme),

                      const SizedBox(height: 48),
                      const VideoResourceCard(
                        title: 'Video recomendado: grafos en acción',
                        description:
                            'Conecta la teoría con problemas reales de rutas, redes y toma de decisiones.',
                        videoUrl: 'https://www.youtube.com/watch?v=dIBxZU__3QA',
                        durationOrAuthor: 'Aplicaciones prácticas',
                      ),
                      const SizedBox(height: 48),

                      // 5. Matrix Representation
                      _buildMatrixExplanationCard(context, colorScheme),
                      const SizedBox(height: 56),

                      // Call to Action Web Banner
                      _buildCtaCard(context, colorScheme),
                    ],
                  ),
                ),
              ),
            ),

            // Web Footer
            _buildWebFooter(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.hub_outlined,
                  color: colorScheme.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONCEPTO CLAVE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La Magia de Conectar Elementos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Text(
            'Un Grafo es una forma visual de organizar información compuesta por dos ingredientes principales:',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nodos (Vértices): Son los puntos o círculos del mapa (pueden ser personas, ciudades, computadoras o tareas).\n\n'
            'Conexiones (Aristas): Son las líneas que conectan a dos nodos, indicando que hay una relación entre ellos (como una amistad, un cable o una calle).',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphVocabularySection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final concepts = [
      (
        'Grado',
        'Cantidad de aristas que inciden en un nodo. En un grafo dirigido se distingue entre grado de entrada y de salida.',
        Icons.numbers_rounded,
      ),
      (
        'Camino',
        'Secuencia de nodos conectados. Los algoritmos de rutas buscan caminos con menor distancia, costo o tiempo.',
        Icons.route_rounded,
      ),
      (
        'Ciclo',
        'Camino que comienza y termina en el mismo nodo. Es común en dependencias, circuitos y redes de transporte.',
        Icons.loop_rounded,
      ),
      (
        'Conectividad',
        'Indica si es posible llegar de una parte del grafo a otra. Los nodos aislados forman componentes separados.',
        Icons.account_tree_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOCABULARIO ESENCIAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuatro ideas para leer cualquier grafo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: concepts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 128,
                ),
                itemBuilder: (context, index) {
                  final concept = concepts[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          concept.$3,
                          color: colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                concept.$1,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  concept.$2,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.3,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixExplanationCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_on_rounded,
                color: colorScheme.secondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Representación en Matriz de Adyacencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Para que una computadora entienda un grafo, se suele usar una tabla numérica llamada Matriz de Adyacencia. Las filas son los nodos de origen y las columnas los de destino; las casillas guardan la distancia o costo entre ellos.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            '¡Crea tus propios grafos visualmente!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Diseña redes interactivas agregando nodos y conexiones directamente en el lienzo.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _navigateToLibrary(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text(
              'Ir a la Aplicación Principal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFooter(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Center(
        child: Text(
          '© Guía Educativa - Concepto de Grafos',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
