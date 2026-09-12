import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'home_library_screen.dart';

class JohnsonAlgoScreen extends StatelessWidget {
  const JohnsonAlgoScreen({super.key});

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
          const WebExplanationNavbar(activePage: ExplanationWebPage.johnson),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(context, colorScheme, width),

                  // Main Content
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
                            // Concept Overview
                            _buildConceptCard(context, colorScheme),
                            const SizedBox(height: 36),

                            _buildLearningSection(
                              context,
                              colorScheme,
                              '¿Qué problema resuelve?',
                              'Johnson ayuda a encontrar la duración mínima de un proyecto cuando sus actividades dependen unas de otras. Permite saber qué tareas no pueden retrasarse sin mover la fecha final.',
                              Icons.flag_outlined,
                            ),
                            const SizedBox(height: 36),

                            _buildProjectElementsSection(context, colorScheme),
                            const SizedBox(height: 36),

                            // Video Tutorial Card
                            const VideoResourceCard(
                              title: '🎥 Video Recomendado: Cálculo de Ruta Crítica y Redes',
                              description: 'Aprende a realizar la pasada de ida (máximos) y de regreso (mínimos) con un ejercicio resuelto paso a paso.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=YfFRfyLxY1Y',
                              durationOrAuthor: 'Explicación en Video',
                            ),
                            const SizedBox(height: 48),

                            const VideoResourceCard(
                              title:
                                  'Video 2: introducción al método de Johnson',
                              description: 'Relaciona las actividades, sus dependencias y los tiempos necesarios para completar un proyecto.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=0YBxkeS0qFM',
                              durationOrAuthor: 'Introducción guiada',
                            ),
                            const SizedBox(height: 48),

                            // Step-by-Step Algorithm Workflow (Forward & Backward)
                            _buildWorkflowSection(context, colorScheme, width),
                            const SizedBox(height: 48),

                            const VideoResourceCard(
                              title: 'Video 3: cálculo de tiempos y holguras',
                              description: 'Refuerza la pasada hacia adelante y hacia atrás con una explicación visual.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=fjrZecb6e8A',
                              durationOrAuthor: 'Procedimiento paso a paso',
                            ),
                            const SizedBox(height: 48),

                            // Human Everyday Example Card
                            _buildHumanAnalogyCard(context, colorScheme),
                            const SizedBox(height: 48),

                            // Critical Path Explanation
                            _buildCriticalPathSection(context, colorScheme),
                            const SizedBox(height: 56),

                            _buildExampleAndComplexitySection(
                              context,
                              colorScheme,
                            ),
                            const SizedBox(height: 48),

                            const VideoResourceCard(
                              title: 'Video 4: ejemplo completo del algoritmo',
                              description: 'Cierra la explicación con un ejercicio aplicado para interpretar la ruta crítica.',
                              videoUrl:
                                  'https://www.youtube.com/watch?v=ZJJhLHeQXoM',
                              durationOrAuthor: 'Ejemplo aplicado',
                            ),
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
            const Color(0xFF00BFA5).withValues(alpha: 0.25),
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
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alt_route_rounded,
                        size: 16,
                        color: Color(0xFF00BFA5),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '⏱️ Tiempos de Ida y Regreso',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Algoritmo de Johnson',
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
                    'Un método intuitivo para calcular tiempos tempranos y tardíos en proyectos. ¡De ida sumamos los máximos y de regreso restamos los mínimos!',
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
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: Color(0xFF00BFA5),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LA REGLA DE ORO DE LAS DOS PASADAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF00BFA5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Cómo funciona el cálculo de tiempos?',
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
            'El algoritmo de Johnson para redes evalúa la secuencia de actividades de un proyecto mediante dos pasadas principales:',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '⏩ 1. Pasada de Ida (Hacia Adelante): Avanzas desde el inicio hasta el final sumando las duraciones. Si a una actividad llegan varias tareas antecedoras, ¡eliges el valor MÁXIMO!\n\n'
            '⏪ 2. Pasada de Regreso (Hacia Atrás): Vuelves desde el final hacia el inicio restando las duraciones. Si de una actividad salen varias tareas, ¡eliges el valor MÍNIMO!',
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
        color: colorScheme.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.foundation_rounded,
            color: Color(0xFF00BFA5),
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Ejemplo Práctico: Construcción de una Casa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No puedes poner las paredes si los cimientos no están secos, y no puedes poner el techo si faltan las paredes. De ida sumas los tiempos para saber cuándo es lo más pronto que puedes poner el techo. De regreso restas para saber qué tareas no pueden retrasarse ni un solo día.',
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

  Widget _buildLearningSection(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
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

  Widget _buildProjectElementsSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _buildLearningSection(
      context,
      colorScheme,
      'Cómo se representa un proyecto',
      'Cada nodo representa un evento o hito y cada conexión representa una actividad con duración. Las flechas muestran el orden obligatorio: una tarea solo comienza cuando sus predecesoras han terminado.',
      Icons.account_tree_outlined,
    );
  }

  Widget _buildExampleAndComplexitySection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _buildLearningSection(
      context,
      colorScheme,
      'Ejemplo, implementación y complejidad',
      'En una obra, preparar el terreno, comprar materiales y construir pueden formar caminos distintos. Johnson recorre la red y conserva los máximos de llegada. Con una lista de actividades y sus dependencias, el cálculo se realiza en tiempo lineal O(V + E), donde V son eventos y E conexiones.',
      Icons.code_rounded,
    );
  }

  Widget _buildWorkflowSection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    final steps = [
      {
        'num': '1',
        'title': 'Pasada de Ida (De Ida)',
        'subtitle': 'Sumar y elegir el MÁXIMO',
        'desc': 'Avanza sumando la duración de cada tarea. En los nodos donde convergen varias actividades antecedoras, escoge siempre el valor máximo.',
      },
      {
        'num': '2',
        'title': 'Pasada de Regreso (De Regreso)',
        'subtitle': 'Restar y elegir el MÍNIMO',
        'desc': 'Retrocede restando las duraciones. En los nodos donde parten o se separan varias actividades hacia adelante, escoge siempre el valor mínimo.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REGLAS DE CÁLCULO PASO A PASO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF00BFA5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Las Dos Pasadas del Algoritmo',
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
            mainAxisExtent: 200,
          ),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final item = steps[index];
            return Container(
              padding: const EdgeInsets.all(22),
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
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            item['num']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              item['subtitle']!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00BFA5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['desc']!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
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

  Widget _buildCriticalPathSection(
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
              const Icon(
                Icons.explore_outlined,
                color: Color(0xFF00BFA5),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Holguras y Ruta Crítica',
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
            '• Holgura: Es la resta entre el tiempo de regreso (tardío) y el tiempo de ida (temprano).\n\n'
            '• Ruta Crítica: El camino formado por las actividades que tienen holgura igual a cero. ¡Cualquier retraso en estas tareas demorará la entrega completa del proyecto!',
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
            const Color(0xFF00BFA5),
            const Color(0xFF00BFA5).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            '¡Calcula la Ruta Crítica en tus Grafos!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa a la aplicación para armar tus redes de nodos y calcular las pasadas de ida y regreso.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _navigateToLibrary(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00BFA5),
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
          '© Guía Educativa - Algoritmo de Johnson (Ruta Crítica)',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
