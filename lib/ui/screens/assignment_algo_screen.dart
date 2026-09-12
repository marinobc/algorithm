import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'home_library_screen.dart';

class AssignmentAlgoScreen extends StatelessWidget {
  const AssignmentAlgoScreen({super.key});

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
          const WebExplanationNavbar(
            activePage: ExplanationWebPage.assignment,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(context, colorScheme, width),

                  // Content Area
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
                            // Concept Overview Card
                            _buildConceptCard(context, colorScheme),
                            const SizedBox(height: 36),

                            // Video Tutorial Card
                            const VideoResourceCard(
                              title:
                                  '🎥 Video Recomendado: Asignación por Matriz de Ceros Explicada',
                              description:
                                  'Mira cómo restar mínimos por filas y columnas para resolver problemas de asignación 1 a 1.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=T4TrFA39AJU&t=673s',
                              durationOrAuthor: 'Explicación en Video',
                            ),
                            const SizedBox(height: 48),

                            // Algorithm Steps (Matrix of Zeros Method)
                            _buildStepsSection(context, colorScheme, width),
                            const SizedBox(height: 48),

                            // Human Everyday Analogy Card
                            _buildHumanAnalogyCard(context, colorScheme),
                            const SizedBox(height: 48),

                            // Conceptual Considerations
                            _buildConceptualFeaturesSection(context, colorScheme),
                            const SizedBox(height: 56),

                            // CTA Card
                            _buildCtaCard(context, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
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
            const Color(0xFF7C4DFF).withValues(alpha: 0.25),
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
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 16,
                        color: Color(0xFF7C4DFF),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '🎯 Asignación Óptima 1 a 1',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Algoritmo de Asignación',
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
                    '¿Cómo repartir tareas a un equipo gastando lo menos posible? ¡Restamos los costos mínimos para crear una tabla de ceros y hacer parejas perfectas!',
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

  Widget _buildConceptCard(BuildContext context, ColorScheme colorScheme) {
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
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.grid_on_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EL TRUCO DE LA MATRIZ DE CEROS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF7C4DFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Por qué restamos valores en la tabla?',
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
            'Si a todas las opciones de una fila le restas el costo de la opción más barata, creas una casilla con valor CERO. Ese cero significa: "¡Esta es la opción óptima para esta fila!"',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Al repetir esto por filas y luego por columnas, construyes un mapa lleno de ceros. El objetivo final es elegir un cero por cada fila y por cada columna sin repetir.',
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
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping_rounded,
              color: Color(0xFF7C4DFF), size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Ejemplo Cotidiano: Repartidores y Entregas Uber/Rappi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tienes 3 repartidores y 3 pedidos en diferentes puntos de la ciudad. El algoritmo resta la distancia más cercana de cada repartidor para encontrar la combinación 1 a 1 que minimiza el consumo total de gasolina.',
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

  Widget _buildStepsSection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    final steps = [
      {
        'step': 'Paso 1',
        'title': 'Reducción por Filas',
        'desc':
            'Resta el menor número de cada fila a todos los elementos de esa fila. ¡Ahora cada fila tiene al menos un cero!',
      },
      {
        'step': 'Paso 2',
        'title': 'Reducción por Columnas',
        'desc':
            'Resta el menor número de cada columna a todas sus celdas para multiplicar los ceros disponibles en la tabla.',
      },
      {
        'step': 'Paso 3',
        'title': 'Cubrir Ceros con Líneas',
        'desc':
            'Trazas el mínimo número de líneas (horizontales o verticales) para tachar todos los ceros existentes.',
      },
      {
        'step': 'Paso 4',
        'title': 'Asignar Parejas Óptimas',
        'desc':
            'Cuando las líneas son iguales al número de filas, seleccionas las casillas con ceros para emparejar cada recurso a su tarea.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENERACIÓN Y SELECCIÓN DE CEROS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF7C4DFF),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pasos Sencillos del Algoritmo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width >= 800 ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 170,
          ),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final item = steps[index];
            return Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['step']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title']!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['desc']!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConceptualFeaturesSection(
    BuildContext context,
    ColorScheme colorScheme,
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
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFF7C4DFF), size: 28),
              const SizedBox(width: 12),
              Text(
                'Propiedades Destacadas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '• Asignación Exclusiva: Garantiza que nadie haga dos tareas al mismo tiempo ni que una tarea quede vacía.\n\n'
            '• Costo Mínimo Asegurado: Las restas relativas garantizan matemáticamente la mejor combinación posible sin tener que probar todas las combinaciones manualmente.',
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

  Widget _buildCtaCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C4DFF),
            const Color(0xFF7C4DFF).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            '¡Prueba el Algoritmo de Asignación!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa a la aplicación para calcular asignaciones de costo mínimo en tus tablas.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _navigateToLibrary(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C4DFF),
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
          '© Guía Educativa - Algoritmo de Asignación',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
