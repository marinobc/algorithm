import 'package:flutter/material.dart';

import '../../algorithms/assignment/ui/assignment_launch_button.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'widgets/assignment/hungarian_hero_section.dart';
import 'widgets/assignment/hungarian_steps_section.dart';

class AssignmentAlgoScreen extends StatelessWidget {
  const AssignmentAlgoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WebExplanationShell(
      activePage: ExplanationWebPage.assignment,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // DIVISION 0: Hero Section
            const HungarianHeroSection(),

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
                          'Ejemplos cotidianos',
                          'Asignar repartidores a pedidos, profesores a cursos o máquinas a trabajos son problemas de asignación: cada recurso recibe una tarea y buscamos el menor costo total.',
                          Icons.lightbulb_outline_rounded,
                        ),
                        const SizedBox(height: 36),
                        const VideoResourceCard(
                          title: 'Video Recomendado: Asignación por Matriz de Ceros Explicada',
                          description: 'Mira cómo restar mínimos por filas y columnas para resolver problemas de asignación 1 a 1.',
                          videoUrl: 'https://www.youtube.com/watch?v=T4TrFA39AJU&t=673s',
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
                        _buildLearningSection(
                          context,
                          colorScheme,
                          'Representación mediante matriz de costos',
                          'Las filas representan recursos y las columnas tareas. Cada celda contiene el costo de asignar ese recurso a esa tarea. Una solución válida selecciona una celda por fila y por columna.',
                          Icons.table_chart_outlined,
                        ),
                        const SizedBox(height: 36),
                        _buildModelSection(context, colorScheme),
                        const SizedBox(height: 36),
                        _buildMethodsSection(context, colorScheme),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 2: métodos de asignación',
                          description: 'Refuerza las estrategias para encontrar una combinación óptima y comparar sus resultados.',
                          videoUrl:
                              'https://www.youtube.com/watch?v=_XvIC2KvWvo',
                          durationOrAuthor: 'Métodos de solución',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // DIVISION 3: Hungarian Algorithm & Steps (Surface Canvas)
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
                        _buildLearningSection(
                          context,
                          colorScheme,
                          'Algoritmo Húngaro',
                          'Es un procedimiento exacto para resolver matrices cuadradas de costos. Convierte el problema en una estructura de ceros y encuentra una selección independiente que cubre todas las filas y columnas.',
                          Icons.auto_graph_rounded,
                        ),
                        const SizedBox(height: 48),
                        const HungarianStepsSection(),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 3: explicación del algoritmo húngaro',
                          description: 'Observa la transformación de la matriz y la elección de ceros paso a paso.',
                          videoUrl: 'https://youtu.be/Rjts-iAq1XE?utm_source=chatgpt.com',
                          durationOrAuthor: 'Explicación principal',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // DIVISION 4: Examples, Implementation & Applications (Alternating Background)
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
                        _buildExampleSection(context, colorScheme),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 4: ejemplo resuelto',
                          description: 'Compara este procedimiento con otra resolución completa de un problema de asignación.',
                          videoUrl: 'https://youtu.be/0Zgdui3GqZo?utm_source=chatgpt.com',
                          durationOrAuthor: 'Ejercicio guiado',
                        ),
                        const SizedBox(height: 48),
                        _buildImplementationSection(context, colorScheme),
                        const SizedBox(height: 48),
                        _buildConceptualFeaturesSection(context, colorScheme),
                        const SizedBox(height: 48),
                        _buildApplicationsSection(context, colorScheme),
                        const SizedBox(height: 48),
                        const VideoResourceCard(
                          title: 'Video 5: aplicaciones de la asignación',
                          description: 'Cierra la lección con ejemplos de cómo este modelo ayuda a tomar decisiones eficientes.',
                          videoUrl:
                              'https://www.youtube.com/watch?v=qPkMRXhEQHI',
                          durationOrAuthor: 'Aplicaciones reales',
                        ),
                        const SizedBox(height: 48),
                        _buildHumanAnalogyCard(context, colorScheme),
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
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_rounded,
            color: Color(0xFF7C4DFF),
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejemplo Cotidiano: Repartidores y Entregas Uber/Rappi',
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
          Icon(icon, color: const Color(0xFF7C4DFF), size: 30),
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

  Widget _buildMethodsSection(BuildContext context, ColorScheme colorScheme) {
    final methods = [
      (
        'Fuerza bruta',
        'Prueba todas las combinaciones. Es sencilla de entender, pero crece demasiado rápido cuando aumentan los elementos.',
        Icons.all_inclusive_rounded,
      ),
      (
        'Algoritmo Húngaro',
        'Encuentra una solución óptima mediante reducciones y ceros independientes, con un costo computacional mucho menor.',
        Icons.auto_awesome_rounded,
      ),
      (
        'Branch and Bound',
        'Explora alternativas y descarta ramas que ya no pueden mejorar la mejor solución encontrada.',
        Icons.account_tree_rounded,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÉTODOS PARA RESOLVERLO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tres caminos para buscar la mejor asignación',
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
                      Icon(method.$3, color: const Color(0xFF7C4DFF), size: 26),
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

  Widget _buildExampleSection(BuildContext context, ColorScheme colorScheme) {
    return _buildLearningSection(
      context,
      colorScheme,
      'Ejemplo resuelto paso a paso',
      'Supón tres técnicos y tres instalaciones. Después de reducir filas y columnas, se cubren los ceros y se elige una pareja por técnico. La suma de las celdas seleccionadas es el costo total de la solución.',
      Icons.fact_check_outlined,
    );
  }

  Widget _buildImplementationSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _buildLearningSection(
      context,
      colorScheme,
      'Implementación y complejidad',
      'En código, la matriz puede almacenarse como una lista de listas. El método Húngaro suele resolverse en O(n³), mientras que probar todas las permutaciones con fuerza bruta crece como O(n!). Por eso el algoritmo resulta práctico para matrices grandes.',
      Icons.code_rounded,
    );
  }

  Widget _buildApplicationsSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _buildLearningSection(
      context,
      colorScheme,
      'Aplicaciones reales',
      'Se utiliza para asignar trabajadores a turnos, vehículos a rutas, máquinas a órdenes de producción, anuncios a espacios y estudiantes a proyectos, siempre buscando reducir tiempo, distancia o costo.',
      Icons.public_rounded,
    );
  }

  Widget _buildModelSection(BuildContext context, ColorScheme colorScheme) {
    final items = [
      (
        'Recursos',
        'Personas, máquinas o vehículos que deben recibir una tarea.',
        Icons.groups_rounded,
      ),
      (
        'Tareas',
        'Trabajos o destinos que deben cubrirse exactamente una vez.',
        Icons.task_alt_rounded,
      ),
      (
        'Costo',
        'Tiempo, distancia o dinero asociado a cada pareja recurso-tarea.',
        Icons.payments_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CÓMO SE PLANTEA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Del problema real a la matriz',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cada fila representa un recurso y cada columna una tarea. La celda en su intersección guarda el costo de realizar esa asignación.',
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
                      Icon(item.$3, color: const Color(0xFF7C4DFF), size: 26),
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
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFF7C4DFF),
                size: 28,
              ),
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
          const AssignmentLaunchButton(),
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
