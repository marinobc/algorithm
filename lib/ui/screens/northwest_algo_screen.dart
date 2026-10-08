import 'package:flutter/material.dart';

import '../../algorithms/northwest/ui/northwest_launch_button.dart';
import '../../algorithms/northwest/ui/widgets/northwest_theory_sections.dart';
import '../widgets/math_rich_text.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';

class NorthwestAlgoScreen extends StatelessWidget {
  const NorthwestAlgoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return WebExplanationShell(
      activePage: ExplanationWebPage.northwest,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // DIVISION 0: Hero Section
            _buildHeroSection(context, colorScheme, width),

            // DIVISION 1: Concept & Initial Video (Surface Canvas)
            Container(
              width: double.infinity,
              color: colorScheme.surface,
              child: Center(
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
                        NorthwestTheorySections.buildConceptCard(
                          context,
                          colorScheme,
                        ),
                        const SizedBox(height: 36),
                        NorthwestTheorySections.buildLearningSection(
                          context,
                          colorScheme,
                          '¿Qué problema resuelve?',
                          'El problema de transporte optimiza el envío de mercancías desde múltiples orígenes (fábricas, almacenes) con una disponibilidad fija, hacia múltiples destinos (tiendas, clientes) con una demanda requerida, minimizando el costo total de flete.',
                          Icons.grid_view_rounded,
                        ),
                        const SizedBox(height: 36),
                        NorthwestTheorySections.buildLearningSection(
                          context,
                          colorScheme,
                          'Auto-Balanceo de Oferta y Demanda',
                          'Si la oferta total no coincide exactamente con la demanda total (red desbalanceada), el algoritmo crea automáticamente un origen o destino ficticio con costo \$0 para garantizar la estabilidad matemática.',
                          Icons.balance_rounded,
                        ),
                        const SizedBox(height: 36),
                        NorthwestTheorySections.buildMathFormulationCard(
                          context,
                          colorScheme,
                        ),
                        const SizedBox(height: 36),
                        const VideoResourceCard(
                          title: 'Video Recomendado: Método de la Esquina Noroeste Explicado',
                          description: 'Aprende a llenar la matriz de transporte paso a paso desde la casilla superior izquierda respetando oferta y demanda.',
                          videoUrl:
                              'https://www.youtube.com/watch?v=0Zgdui3GqZo',
                          durationOrAuthor: 'Explicación en Video',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // DIVISION 2: Matrix Representation & Methods (Alternating Background)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Center(
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
                        NorthwestTheorySections.buildModelSection(
                          context,
                          colorScheme,
                        ),
                        const SizedBox(height: 36),
                        NorthwestTheorySections.buildMethodsSection(
                          context,
                          colorScheme,
                        ),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 2: Matriz de Transporte y Balanceo',
                          description: 'Descubre cómo estructurar la tabla de transporte y agregar filas o columnas ficticias con costo cero.',
                          videoUrl:
                              'https://www.youtube.com/watch?v=T4TrFA39AJU',
                          durationOrAuthor: 'Matriz de Transporte',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // DIVISION 3: Algorithm Steps & Optimization (Surface Canvas)
            Container(
              width: double.infinity,
              color: colorScheme.surface,
              child: Center(
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
                        _buildStepsSection(context, colorScheme, width),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 3: Optimización con Método MODI (u-v)',
                          description: 'Observa cómo usar los multiplicadores u-v y realizar circuitos cerrados para alcanzar el menor costo global.',
                          videoUrl:
                              'https://www.youtube.com/watch?v=YfFRfyLxY1Y',
                          durationOrAuthor: 'Optimización MODI',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // DIVISION 4: Real Examples & Call-to-Action (Alternating Background)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Center(
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
                        _buildHumanAnalogyCard(context, colorScheme),
                        const SizedBox(height: 48),
                        NorthwestTheorySections.buildLearningSection(
                          context,
                          colorScheme,
                          'Complejidad y Solución Computacional',
                          r'En código, la tabla se representa mediante vectores de oferta y demanda junto con una matriz de costos. La solución inicial requiere $O(m + n)$ iteraciones, mientras que el análisis de optimalidad MODI evita evaluar arbitrariamente $m^n$ combinaciones.',
                          Icons.code_rounded,
                        ),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 4: Ejemplo Completo de Transporte Resuelto',
                          description: 'Ejercicio guiado paso a paso desde el planteamiento de la red hasta el resultado óptimo final.',
                          videoUrl:
                              'https://www.youtube.com/watch?v=_XvIC2KvWvo',
                          durationOrAuthor: 'Ejercicio Aplicado',
                        ),
                        const SizedBox(height: 48),
                        _buildCtaCard(context, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // DIVISION 5: Footer
            _buildWebFooter(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    const accentColor = Color(0xFFE54872);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withValues(alpha: 0.25), colorScheme.surface],
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
                      color: accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Optimización de Transporte',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Algoritmo de la Esquina Noroeste',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width >= 800 ? 38 : 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Método directo para generar una distribución inicial en problemas de transporte balanceados y desbalanceados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const NorthwestLaunchButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsSection(
    BuildContext context,
    ColorScheme colorScheme,
    double width,
  ) {
    const accentColor = Color(0xFFE54872);

    final steps = [
      {
        'step': 'Paso 1',
        'title': 'Verificar Balance de Red',
        'desc': 'Suma oferta total y demanda total. Si difieren, inserta un origen o destino ficticio con costo \$0.',
      },
      {
        'step': 'Paso 2',
        'title': 'Asignación Noroeste',
        'desc': 'Ubícate en la celda (1,1). Asigna el valor mínimo entre la oferta disponible y la demanda requerida.',
      },
      {
        'step': 'Paso 3',
        'title': 'Avanzar en la Tabla',
        'desc': 'Si agotas la oferta de la fila, avanza a la fila inferior. Si agotas la demanda, avanza a la columna derecha.',
      },
      {
        'step': 'Paso 4',
        'title': 'Optimizar con MODI',
        'desc': r'Calcula los valores $u_i$ y $v_j$ en celdas asignadas. Evalúa el índice $\Delta_{ij} = c_{ij} - u_i - v_j$ en vacías y realiza bucles de ajuste.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROCEDIMIENTO PASO A PASO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pasos del Algoritmo Northwest + MODI',
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
                          color: accentColor,
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: accentColor.withValues(alpha: 0.6),
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
                  Expanded(
                    child: MathRichText(
                      text: item['desc']!,
                      baseStyle: TextStyle(
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
        ),
      ],
    );
  }

  Widget _buildHumanAnalogyCard(BuildContext context, ColorScheme colorScheme) {
    const accentColor = Color(0xFFE54872);

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.grid_view_rounded, color: accentColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejemplo Real: Logística de Centros de Distribución',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Una cadena de supermercados tiene 3 centros de distribución regionales y debe surtir 4 sucursales. Esquina Noroeste establece las rutas iniciales para garantizar stock en todas las tiendas, y el método MODI reorganiza los viajes ahorrando combustible.',
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

  Widget _buildCtaCard(BuildContext context, ColorScheme colorScheme) {
    const accentColor = Color(0xFFE54872);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text(
            '¡Prueba el Algoritmo Northwest!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresa a la aplicación para armar redes de transporte y calcular envíos de costo mínimo.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 20),
          NorthwestLaunchButton(),
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
          '© Guía Educativa - Algoritmo Northwest (Esquina Noroeste)',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
