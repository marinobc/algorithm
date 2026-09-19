import 'package:flutter/material.dart';

import '../../algorithms/northwest/ui/northwest_launch_button.dart';
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
                        _buildConceptCard(context, colorScheme),
                        const SizedBox(height: 36),
                        _buildLearningSection(
                          context,
                          colorScheme,
                          '¿Qué problema resuelve?',
                          'El problema de transporte optimiza el envío de mercancías desde múltiples orígenes (fábricas, almacenes) con una disponibilidad fija, hacia múltiples destinos (tiendas, clientes) con una demanda requerida, minimizando el costo total de flete.',
                          Icons.grid_view_rounded,
                        ),
                        const SizedBox(height: 36),
                        _buildLearningSection(
                          context,
                          colorScheme,
                          'Auto-Balanceo de Oferta y Demanda',
                          'Si la oferta total no coincide exactamente con la demanda total (red desbalanceada), el algoritmo crea automáticamente un origen o destino ficticio con costo \$0 para garantizar la estabilidad matemática.',
                          Icons.balance_rounded,
                        ),
                        const SizedBox(height: 36),
                        _buildMathFormulationCard(context, colorScheme),
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
                        _buildModelSection(context, colorScheme),
                        const SizedBox(height: 36),
                        _buildMethodsSection(context, colorScheme),
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
                        _buildImplementationSection(context, colorScheme),
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
                        'Distribución y Transporte de Costo Mínimo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Algoritmo Northwest',
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
                    '¿Cómo enviar bienes de múltiples fábricas a múltiples tiendas minimizando el costo total? ¡Asignamos oferta y demanda comenzando en la Esquina Noroeste y optimizamos con el método MODI!',
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
    const accentColor = Color(0xFFE54872);

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
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LA REGLA DE LA ESQUINA NOROESTE Y MODI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Cómo funciona la asignación inicial y optimización?',
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
            'El método de la Esquina Noroeste arranca en la celda superior izquierda de la tabla de transporte (fila 1, columna 1). Asigna la máxima cantidad posible entre la oferta del origen y la demanda del destino.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Al agotar la oferta de una fila, avanza hacia abajo; al agotar la demanda de una columna, avanza a la derecha. Una vez generada la solución básica, se aplican los multiplicadores u-v (método MODI) para verificar si existen rutas de flete aún más económicas.',
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

  Widget _buildLearningSection(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String description,
    IconData icon,
  ) {
    const accentColor = Color(0xFFE54872);

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
          Icon(icon, color: accentColor, size: 30),
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

  Widget _buildModelSection(BuildContext context, ColorScheme colorScheme) {
    const accentColor = Color(0xFFE54872);

    final items = [
      (
        'Orígenes (Oferta)',
        'Fábricas, almacenes o centros de acopio con cantidad disponible de bienes.',
        Icons.inventory_2_outlined,
      ),
      (
        'Destinos (Demanda)',
        'Tiendas, distribuidores o clientes con requerimientos específicos.',
        Icons.flag_outlined,
      ),
      (
        'Costos de Flete',
        'Costo unitario por transportar bienes de cada origen a cada destino.',
        Icons.attach_money_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ELEMENTOS DEL MODELO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Estructura de la Matriz de Transporte',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cada fila representa un punto de origen y cada columna un punto de destino. Las celdas guardan el costo unitario de transporte.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 142,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(18),
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
                      Icon(item.$3, color: accentColor, size: 26),
                      const SizedBox(height: 9),
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          item.$2,
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

  Widget _buildMethodsSection(BuildContext context, ColorScheme colorScheme) {
    const accentColor = Color(0xFFE54872);

    final methods = [
      (
        'Esquina Noroeste',
        'Método sistemático inicial. No analiza costos pero genera una solución básica factible rápidamente.',
        Icons.grid_view_rounded,
      ),
      (
        'Costo Mínimo',
        'Prioriza celdas con menor tarifa de flete para obtener una solución inicial más económica.',
        Icons.savings_outlined,
      ),
      (
        'Método MODI (u-v)',
        'Calcula multiplicadores para evaluar celdas vacías y reajustar envíos hasta el óptimo global.',
        Icons.auto_graph_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MÉTODOS DE SOLUCIÓN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fases para Resolver Transporte',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: methods.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 174,
              ),
              itemBuilder: (context, index) {
                final method = methods[index];
                return Container(
                  padding: const EdgeInsets.all(18),
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
                      Icon(method.$3, color: accentColor, size: 26),
                      const SizedBox(height: 10),
                      Text(
                        method.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          method.$2,
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
                  MathRichText(
                    text: item['desc']!,
                    baseStyle: TextStyle(
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

  Widget _buildImplementationSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _buildLearningSectionWithMath(
      context,
      colorScheme,
      'Complejidad y Solución Computacional',
      r'En código, la tabla se representa mediante vectores de oferta y demanda junto con una matriz de costos. La solución inicial requiere $O(m + n)$ iteraciones, mientras que el análisis de optimalidad MODI evita evaluar arbitrariamente $m^n$ combinaciones.',
      Icons.code_rounded,
    );
  }

  Widget _buildLearningSectionWithMath(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String description,
    IconData icon,
  ) {
    const accentColor = Color(0xFFE54872);

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
          Icon(icon, color: accentColor, size: 30),
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
                MathRichText(
                  text: description,
                  baseStyle: TextStyle(
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

  Widget _buildMathFormulationCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    const accentColor = Color(0xFFE54872);

    return Container(
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.functions_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FORMULACIÓN MATEMÁTICA DEL PROBLEMA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Modelo General de Programación Lineal',
                      style: TextStyle(
                        fontSize: 20,
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

          // 1. Función Objetivo
          Text(
            '1. Función Objetivo (Minimizar Costo Total):',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: MathRichText(
                  text: r'Min  Z  =  $\sum_{i=1}^{m} \sum_{j=1}^{n} c_{ij} \cdot x_{ij}$',
                  baseStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  mathColor: colorScheme.primary,
                  mathBgColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Restricciones
          Text(
            '2. Restricciones de Disponibilidad y Demanda:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: isWide
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.only(
                        right: isWide ? 8 : 0,
                        bottom: isWide ? 0 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: accentColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Oferta (Filas):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          MathRichText(
                            text:
                                r'$\sum_{j=1}^{n} x_{ij} = a_i$   (∀ i = 1..m)',
                            baseStyle: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            mathColor: colorScheme.onSurface,
                            mathBgColor: Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.only(left: isWide ? 8 : 0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 18,
                                color: accentColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Demanda (Columnas):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          MathRichText(
                            text:
                                r'$\sum_{i=1}^{m} x_{ij} = b_j$   (∀ j = 1..n)',
                            baseStyle: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            mathColor: colorScheme.onSurface,
                            mathBgColor: Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Condición MODI u-v
          Text(
            '3. Condición de Optimalidad MODI (u-v):',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Celdas Básicas:  ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    MathRichText(
                      text: r'$u_i + v_j = c_{ij}$',
                      mathColor: accentColor,
                      mathBgColor: accentColor.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Celdas No Básicas:  ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    MathRichText(
                      text: r'$\Delta_{ij} = c_{ij} - (u_i + v_j) \ge 0$',
                      mathColor: colorScheme.primary,
                      mathBgColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
