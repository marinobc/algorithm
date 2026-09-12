import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'home_library_screen.dart';

class WhatAreGraphsScreen extends StatelessWidget {
  const WhatAreGraphsScreen({super.key});

  void _navigateToLibrary(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeLibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = M3Palette.of(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: palette.canvasBg,
      body: Column(
        children: [
          const WebExplanationNavbar(activePage: ExplanationWebPage.graphs),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(context, colorScheme, width),

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

                            // Video Tutorial Card
                            const VideoResourceCard(
                              title: 'Video recomendado: Introducción a los grafos',
                              description: 'Aprende de forma visual con ejemplos interactivos qué son los nodos y las conexiones.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=vnNFiNVy9KM',
                              durationOrAuthor: 'Explicación en Video',
                            ),
                            const SizedBox(height: 20),
                            const VideoResourceCard(
                              title:
                                  'Video recomendado: conceptos fundamentales',
                              description: 'Refuerza la diferencia entre vértices, aristas y las relaciones que modelan.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=F5Xjpg0-NhM',
                              durationOrAuthor: 'Teoría de Grafos',
                            ),
                            const SizedBox(height: 48),

                            // 2. Fundamental Anatomy of Graphs
                            _buildAnatomySection(context, colorScheme, width),
                            const SizedBox(height: 48),

                            _buildApplicationsSection(context, colorScheme),
                            const SizedBox(height: 48),

                            _buildGraphVocabularySection(context, colorScheme),
                            const SizedBox(height: 48),

                            const VideoResourceCard(
                              title: 'Video recomendado: tipos de grafos',
                              description: 'Descubre cómo cambian los grafos cuando sus conexiones tienen dirección o peso.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=_A9EpjnmZz4',
                              durationOrAuthor: 'Clasificación y ejemplos',
                            ),
                            const SizedBox(height: 48),

                            // 3. Human Real-World Analogy Card
                            _buildHumanAnalogyCard(context, colorScheme),
                            const SizedBox(height: 48),

                            // 4. Types of Graphs
                            _buildGraphTypesSection(
                              context,
                              colorScheme,
                              width,
                            ),
                            const SizedBox(height: 48),

                            const VideoResourceCard(
                              title: 'Video recomendado: grafos en acción',
                              description: 'Conecta la teoría con problemas reales de rutas, redes y toma de decisiones.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=dIBxZU__3QA',
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.secondaryContainer.withValues(alpha: 0.35),
            colorScheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 56.0,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bubble_chart_rounded,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🌐 Visualiza Conexiones y Redes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¿Qué son los Grafos?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width > 700 ? 42 : 30,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Text(
                    'Imagínate un mapa donde las ciudades son puntos y las carreteras los caminos que las unen. ¡Eso es un grafo! Una forma súper intuitiva de representar cómo se conectan las cosas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width > 700 ? 18 : 15,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            '🔴 Nodos (Vértices): Son los puntos o círculos del mapa (pueden ser personas, ciudades, computadoras o tareas).\n\n'
            '➡️ Conexiones (Aristas): Son las líneas que conectan a dos nodos, indicando que hay una relación entre ellos (como una amistad, un cable o una calle).',
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

  Widget _buildHumanAnalogyCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.emoji_objects_rounded,
            color: colorScheme.tertiary,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Ejemplo Cotidiano: Red Social de Amigos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Imagina Facebook o Instagram: cada persona es un NODO y cada "seguimiento" o "solicitud aceptada" es una CONEXIÓN. Cuando la app te dice "Sugerencias de amigos en común", un algoritmo analiza el grafo buscando nodos conectados entre tus amigos.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final applications = [
      (
        'Mapas y transporte',
        'Las ciudades son nodos y las carreteras son aristas con distancia o tiempo.',
        Icons.map_outlined,
      ),
      (
        'Internet',
        'Los dispositivos y servidores se conectan para enviar información por distintas rutas.',
        Icons.language_rounded,
      ),
      (
        'Recomendaciones',
        'Las relaciones entre usuarios, productos o contenidos ayudan a encontrar opciones relevantes.',
        Icons.recommend_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOS GRAFOS EN LA VIDA REAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Una misma idea, muchas aplicaciones',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800
                ? 3
                : constraints.maxWidth >= 500
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applications.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 156,
              ),
              itemBuilder: (context, index) {
                final application = applications[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        application.$3,
                        color: colorScheme.secondary,
                        size: 26,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        application.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Text(
                          application.$2,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
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

  Widget _buildAnatomySection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ELEMENTOS PRINCIPALES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Anatomía Básica de un Grafo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildAnatomyCard(
                    context,
                    title: '1. Nodos o Vértices',
                    icon: Icons.circle_outlined,
                    color: const Color(0xFF7C4DFF),
                    description: 'Son las entidades individuales de la red que guardan datos como su nombre o estado.',
                  ),
                ),
                SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildAnatomyCard(
                    context,
                    title: '2. Aristas o Enlaces',
                    icon: Icons.alt_route_rounded,
                    color: const Color(0xFF00BFA5),
                    description: 'Son los enlaces que indican interacción o posibilidad de viaje de un nodo a otro.',
                  ),
                ),
                SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildAnatomyCard(
                    context,
                    title: '3. Pesos o Costos',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFFFF5252),
                    description: 'Es el "costo", la distancia o el tiempo que toma atravesar esa conexión concreta.',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnatomyCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphTypesSection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VARIEDAD DE CONEXIONES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Hacia dónde fluyen los datos?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '➡️ Grafos Dirigidos (Digrafos)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las conexiones tienen un sentido único (como una calle de una sola vía o un mensaje de Twitter donde tú sigues a alguien pero no necesariamente te sigue a ti).',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔄 Grafos No Dirigidos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las conexiones funcionan en ambos sentidos por igual (como una llamada telefónica o dos amigos en Facebook).',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            children: [
              Icon(Icons.grid_on_rounded, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Representación en Matriz de Adyacencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
