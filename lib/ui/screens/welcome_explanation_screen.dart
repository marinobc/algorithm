import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'home_library_screen.dart';

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

  void _navigateToLibrary(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeLibraryScreen()),
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = M3Palette.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: palette.canvasBg,
      body: Column(
        children: [
          // 1. Web Header / Navbar
          const WebExplanationNavbar(
            activePage: ExplanationWebPage.algorithms,
          ),

          // 2. Main Web Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section Banner
                  _buildWebHeroSection(context, colorScheme, screenWidth),

                  // Main Content Area with Max Width Container
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
                            // Explanation Web Card / Banner
                            _buildExplanationWebSection(context, colorScheme),

                            const SizedBox(height: 56),

                            _buildSectionHeader(
                              context,
                              badge: 'RECURSOS AUDIOVISUALES',
                              title: 'Videos para reforzar la idea de algoritmo',
                              subtitle:
                                  'Dos explicaciones introductorias para conectar la teoría con ejemplos y procesos paso a paso.',
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
                                subtitle:
                                    'Descubre cómo la lógica algorítmica resuelve problemas cotidianos a gran escala.',
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Examples Grid (Responsive 1 to 3 columns)
                            _buildExamplesGrid(context, screenWidth),

                            const SizedBox(height: 60),

                            // Call to Action Banner (Web style banner)
                            _buildCallToActionWebCard(context, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Web Footer
                  _buildWebFooter(context, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Web Hero Section ---
  Widget _buildWebHeroSection(
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
            colorScheme.primaryContainer.withValues(alpha: 0.4),
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
              vertical: 60.0,
            ),
            child: Column(
              children: [
                // Top Web Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aprende Conceptos Fundamentales',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Web Headline
                Text(
                  '¿Qué son los Algoritmos y para qué sirven?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width > 700 ? 42 : 30,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -1,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),

                // Web Subhead Description
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Text(
                    'Descubre la lógica que impulsa la tecnología moderna, optimiza procesos diarios y resuelve los problemas computacionales más complejos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width > 700 ? 18 : 15,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Hero CTA Buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _navigateToLibrary(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                      label: const Text(
                        'Explorar Biblioteca de Grafos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _scrollToExamples,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                      label: const Text(
                        'Ver 3 Ejemplos Prácticos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Explanation Web Section ---
  Widget _buildExplanationWebSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.primary,
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
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Qué es un Algoritmo y por qué es fundamental?',
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
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Text(
            'Un algoritmo es una secuencia lógica, finita, precisa y ordenada de pasos o instrucciones diseñadas para resolver un problema específico, realizar una tarea bien definida o procesar datos.',
            style: TextStyle(
              fontSize: 17,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'En el mundo moderno, los algoritmos son el motor detrás del software. Permiten que los sistemas informáticos automaticen tareas complejas, tomen decisiones basadas en datos de manera rápida y eficiente, y ahorren recursos valiosos como tiempo y memoria de procesamiento.',
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

  Widget _buildVideosSection(BuildContext context, double width) {
    const videos = [
      VideoResourceCard(
        title: 'Introducción visual a los algoritmos',
        description:
            'Un recurso de apoyo para entender cómo una serie de instrucciones ordenadas permite resolver problemas de forma clara y repetible.',
        videoUrl: 'https://www.youtube.com/watch?v=U3CGMyjzlvM',
        durationOrAuthor: 'Video introductorio',
      ),
      VideoResourceCard(
        title: 'Algoritmos explicados paso a paso',
        description:
            'Material complementario para repasar conceptos básicos, ejemplos y la lógica detrás de la resolución estructurada de problemas.',
        videoUrl:
            'https://www.youtube.com/watch?v=FS9u9cIGf3o&list=PLYYyYpMvAtD1Gu8o1734Ld22LTDxlfKfO',
        durationOrAuthor: 'Lista de reproducción',
      ),
    ];

    if (width < 760) {
      return Column(
        children: [
          videos[0],
          const SizedBox(height: 20),
          videos[1],
        ],
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

  // --- Section Header Helper ---
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
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // --- Examples Grid (1, 2 or 3 Columns) ---
  Widget _buildExamplesGrid(BuildContext context, double width) {
    int crossAxisCount = 1;
    if (width >= 900) {
      crossAxisCount = 3;
    } else if (width >= 600) {
      crossAxisCount = 2;
    }

    final examples = [
      {
        'number': '01',
        'title': 'Navegación y Rutas GPS',
        'subtitle': 'Google Maps, Waze, Logística',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF00BFA5),
        'image':
            'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&auto=format&fit=crop',
        'description':
            'Al solicitar una ruta en tu teléfono, un algoritmo analiza miles de calles, intersecciones y condiciones de tráfico en vivo para calcular en milisegundos el trayecto óptimo hasta tu destino.',
      },
      {
        'number': '02',
        'title': 'Búsqueda y Recomendaciones',
        'subtitle': 'Google, Spotify, Redes Sociales',
        'icon': Icons.manage_search_rounded,
        'color': const Color(0xFF7C4DFF),
        'image':
            'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=600&auto=format&fit=crop',
        'description':
            'Cuando buscas información o escuchas música, los algoritmos examinan e indexan millones de datos para mostrarte de inmediato los resultados más relevantes según tu contexto e historial.',
      },
      {
        'number': '03',
        'title': 'Organización y Clasificación',
        'subtitle': 'Filtros, Precios, Catálogos',
        'icon': Icons.sort_rounded,
        'color': const Color(0xFFFF5252),
        'image':
            'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600&auto=format&fit=crop',
        'description':
            'Desde ordenar contactos o correos electrónicos por fecha hasta estructurar inventarios de tiendas electrónicas, los algoritmos de ordenamiento permiten priorizar datos velozmente.',
      },
    ];

    if (crossAxisCount == 1) {
      return Column(
        children: examples
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildExampleWebCard(context, e),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 455,
      ),
      itemCount: examples.length,
      itemBuilder: (context, index) {
        return _buildExampleWebCard(context, examples[index]);
      },
    );
  }

  // --- Example Web Card ---
  Widget _buildExampleWebCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = data['color'] as Color;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Image
          if (data['image'] != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                data['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: accentColor.withValues(alpha: 0.2)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        data['icon'] as IconData,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    Text(
                      data['number'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  data['title'] as String,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
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

  // --- Call to Action Web Banner ---
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
          const Icon(
            Icons.hub_outlined,
            size: 48,
            color: Colors.white,
          ),
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
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToLibrary(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            label: const Text(
              'Ir a la Aplicación Principal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Web Footer ---
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Editor de Nodos y Algoritmos de Grafos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateToLibrary(context),
                    icon: const Icon(Icons.launch_rounded, size: 16),
                    label: const Text('Biblioteca Principal'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                '© Guía Educativa de Algoritmos. Diseñado como plataforma de aprendizaje interactivo.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
