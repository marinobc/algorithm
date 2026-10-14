import 'package:flutter/material.dart';

import '../../domain/services/base_sorting_algorithm.dart';
import '../../domain/services/sorting_steps.dart';
import '../widgets/sorting_pin_visualizer.dart';
import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'sorting_visualizer_screen.dart';

/// Página explicativa de un algoritmo de ordenamiento (Selection, Insertion,
/// Shell y Merge). Sigue la misma estructura por "divisiones" que las páginas
/// de Asignación, Johnson y Northwest.
class SortingAlgoScreen extends StatelessWidget {
  final BaseSortingAlgorithm algorithm;

  const SortingAlgoScreen({super.key, required this.algorithm});

  bool get _insertion => algorithm.id == 'insertion';

  ExplanationWebPage get _page => switch (algorithm.id) {
    'selection' => ExplanationWebPage.selectionSort,
    'insertion' => ExplanationWebPage.insertionSort,
    'shell' => ExplanationWebPage.shellSort,
    _ => ExplanationWebPage.mergeSort,
  };

  SortingPageContent get _c => SortingPageContent.forId(algorithm.id);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final c = _c;
    final example = _insertion ? [3, 7, 4, 9] : [8, 3, 6, 2];
    final initial = algorithm.buildTimeline(example).steps.first;
    final videos = c.videos;

    return WebExplanationShell(
      activePage: _page,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // DIVISION 0: Hero
            _buildHero(context, colors, c),

            // DIVISION 1: Concepto + cómo funciona + primer video (surface)
            _division(
              colors,
              tone: _Tone.surface,
              children: [
                _buildConceptCard(context, colors, c),
                const SizedBox(height: 36),
                _buildHowSection(context, colors, c, example, initial),
                const SizedBox(height: 36),
                _buildAnalogyCard(context, colors, c),
                const SizedBox(height: 36),
                _video(videos, 0),
              ],
            ),

            // DIVISION 2: Paso a paso + traza + segundo video (alternado)
            _division(
              colors,
              tone: _Tone.low,
              children: [
                _buildStepsSection(context, colors, c),
                const SizedBox(height: 36),
                _buildTraceSection(context, colors, c),
                if (videos.length > 1) ...[
                  const SizedBox(height: 48),
                  _video(videos, 1),
                ],
              ],
            ),

            // DIVISION 3: Complejidad + comparación + tercer video (surface)
            _division(
              colors,
              tone: _Tone.surface,
              children: [
                _buildComplexitySection(context, colors, c),
                if (videos.length > 2) ...[
                  const SizedBox(height: 48),
                  _video(videos, 2),
                ],
              ],
            ),

            // DIVISION 4: Pros/contras, cuándo usarlo y CTA (alternado)
            _division(
              colors,
              tone: _Tone.high,
              children: [
                _buildProsConsSection(context, colors, c),
                const SizedBox(height: 36),
                _buildWhenCard(context, colors, c),
                const SizedBox(height: 48),
                _buildCtaCard(context, c),
              ],
            ),

            // DIVISION 5: Footer
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estructura base
  // ---------------------------------------------------------------------------

  Widget _division(
    ColorScheme colors, {
    required _Tone tone,
    required List<Widget> children,
  }) {
    final bordered = tone != _Tone.surface;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: switch (tone) {
          _Tone.surface => colors.surface,
          _Tone.low => colors.surfaceContainerLow,
          _Tone.high => colors.surfaceContainerHigh.withValues(alpha: 0.5),
        },
        border: bordered
            ? Border.symmetric(
                horizontal: BorderSide(
                  color: colors.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              )
            : null,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _video(List<SortingVideo> videos, int index) {
    final v = videos[index];
    return VideoResourceCard(
      title: v.title,
      description: v.description,
      videoUrl: v.url,
      durationOrAuthor: v.label,
    );
  }

  BoxDecoration _cardDecoration(ColorScheme colors, {double radius = 20}) =>
      BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      );

  Widget _eyebrow(ColorScheme colors, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: algorithm.accentColor,
    ),
  );

  Widget _sectionTitle(ColorScheme colors, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: colors.onSurface,
    ),
  );

  Widget _body(ColorScheme colors, String text, {double size = 15}) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.6,
      color: colors.onSurfaceVariant,
    ),
  );

  // ---------------------------------------------------------------------------
  // DIVISION 0: Hero
  // ---------------------------------------------------------------------------

  Widget _buildHero(BuildContext context, ColorScheme colors, SortingPageContent c) {
    final accent = algorithm.accentColor;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.25), colors.surface],
        ),
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.badgeIcon, size: 16, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        c.badge,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  algorithm.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width > 700 ? 42 : 30,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Text(
                    c.intro,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width > 700 ? 18 : 15,
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _launchButton(context, algorithm.name),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIVISION 1
  // ---------------------------------------------------------------------------

  Widget _buildConceptCard(BuildContext context, ColorScheme colors, SortingPageContent c) {
    final accent = algorithm.accentColor;
    return Container(
      decoration: _cardDecoration(colors, radius: 24),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(c.heroIcon, color: accent, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eyebrow(colors, c.conceptEyebrow),
                    const SizedBox(height: 4),
                    Text(
                      c.conceptTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
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
            c.conceptBody,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _body(colors, c.conceptExtra),
        ],
      ),
    );
  }

  Widget _buildHowSection(
    BuildContext context,
    ColorScheme colors,
    SortingPageContent c,
    List<int> example,
    SortingStep initial,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: algorithm.accentColor, size: 28),
              const SizedBox(width: 12),
              Text(
                '¿Cómo funciona?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            c.how,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _body(colors, c.howExtra),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              height: 270,
              child: SortingPinVisualizer(
                values: example,
                previous: initial,
                current: initial,
                progress: const AlwaysStoppedAnimation<double>(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalogyCard(BuildContext context, ColorScheme colors, SortingPageContent c) {
    final accent = algorithm.accentColor;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.style_rounded, color: accent, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.analogyTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.analogyBody,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIVISION 2
  // ---------------------------------------------------------------------------

  Widget _buildStepsSection(BuildContext context, ColorScheme colors, SortingPageContent c) {
    final accent = algorithm.accentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(colors, 'EL PROCEDIMIENTO'),
        const SizedBox(height: 6),
        _sectionTitle(colors, 'Paso a paso'),
        const SizedBox(height: 20),
        ...c.steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_forward_rounded, color: accent, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.$2,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _body(colors, step.$3, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTraceSection(BuildContext context, ColorScheme colors, SortingPageContent c) {
    final accent = algorithm.accentColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(colors, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ejemplo resuelto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.example,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          ...c.trace.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        row.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    Text(
                      row.state,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: colors.onSurface,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(
                        row.note,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIVISION 3
  // ---------------------------------------------------------------------------

  Widget _buildComplexitySection(BuildContext context, ColorScheme colors, SortingPageContent c) {
    final accent = algorithm.accentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(colors, 'EFICIENCIA'),
        const SizedBox(height: 6),
        _sectionTitle(colors, 'Complejidad'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: _cardDecoration(colors, radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.complexity,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                c.complexityDetails,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DIVISION 4
  // ---------------------------------------------------------------------------

  Widget _buildProsConsSection(BuildContext context, ColorScheme colors, SortingPageContent c) {
    Widget panel({
      required String title,
      required IconData icon,
      required Color color,
      required List<String> items,
    }) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 7, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _body(colors, t, size: 14.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final pros = panel(
      title: 'Ventajas',
      icon: Icons.thumb_up_alt_rounded,
      color: const Color(0xFF2E9E5B),
      items: c.pros,
    );
    final cons = panel(
      title: 'Limitaciones',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFD9822B),
      items: c.cons,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(colors, 'BALANCE'),
        const SizedBox(height: 6),
        _sectionTitle(colors, 'Ventajas y limitaciones'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: pros),
                  const SizedBox(width: 16),
                  Expanded(child: cons),
                ],
              );
            }
            return Column(children: [pros, const SizedBox(height: 16), cons]);
          },
        ),
      ],
    );
  }

  Widget _buildWhenCard(BuildContext context, ColorScheme colors, SortingPageContent c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(colors, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  color: algorithm.accentColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.whenTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _body(colors, c.whenBody),
        ],
      ),
    );
  }

  Widget _buildCtaCard(BuildContext context, SortingPageContent c) {
    final accent = algorithm.accentColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            '¡Prueba ${algorithm.name} en el laboratorio!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.cta,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          _launchButton(context, algorithm.name),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Center(
        child: Text(
          '© Guía Educativa - ${algorithm.name}',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _launchButton(BuildContext context, String title) =>
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SortingVisualizerScreen(algorithm: algorithm),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text('Probar $title'),
      );
}

enum _Tone { surface, low, high }

// =============================================================================
// CONTENIDO (textos y enlaces de video de cada algoritmo)
// =============================================================================

/// Video recomendado dentro de una página explicativa de ordenamiento.
class SortingVideo {
  final String title;
  final String description;
  final String url;
  final String label;

  const SortingVideo({
    required this.title,
    required this.description,
    required this.url,
    required this.label,
  });
}

/// Una fila de la traza de ejemplo (estado del arreglo tras cada paso).
class SortingTraceRow {
  final String label;
  final String state;
  final String note;

  const SortingTraceRow(this.label, this.state, this.note);
}

/// Contenido textual completo de la página de un algoritmo de ordenamiento.
///
/// Vive separado de la UI para poder editar los textos y los enlaces de video
/// sin tocar widgets.
class SortingPageContent {
  final String badge;
  final IconData badgeIcon;
  final IconData heroIcon;
  final String intro;

  final String conceptEyebrow;
  final String conceptTitle;
  final String conceptBody;
  final String conceptExtra;

  final String how;
  final String howExtra;

  final String analogyTitle;
  final String analogyBody;

  /// (título, descripción corta, detalle ampliado)
  final List<(String, String, String)> steps;

  final String example;
  final List<SortingTraceRow> trace;

  final String complexity;
  final String complexityDetails;
  final String complexityExtra;

  /// (etiqueta, valor)
  final List<(String, String)> metrics;

  final List<String> pros;
  final List<String> cons;

  final String whenTitle;
  final String whenBody;

  final String cta;

  final List<SortingVideo> videos;

  const SortingPageContent({
    required this.badge,
    required this.badgeIcon,
    required this.heroIcon,
    required this.intro,
    required this.conceptEyebrow,
    required this.conceptTitle,
    required this.conceptBody,
    required this.conceptExtra,
    required this.how,
    required this.howExtra,
    required this.analogyTitle,
    required this.analogyBody,
    required this.steps,
    required this.example,
    required this.trace,
    required this.complexity,
    required this.complexityDetails,
    required this.complexityExtra,
    required this.metrics,
    required this.pros,
    required this.cons,
    required this.whenTitle,
    required this.whenBody,
    required this.cta,
    required this.videos,
  });

  static SortingPageContent forId(String id) => switch (id) {
    'selection' => _selection,
    'insertion' => _insertion,
    'shell' => _shell,
    _ => _merge,
  };

  // ---------------------------------------------------------------------------
  // SELECTION SORT
  // ---------------------------------------------------------------------------
  static const _selection = SortingPageContent(
    badge: 'Ordenamiento por selección',
    badgeIcon: Icons.sort_rounded,
    heroIcon: Icons.sort_rounded,
    intro:
        'Encuentra el menor elemento del tramo pendiente y colócalo en su posición definitiva.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Por qué se llama "selección"?',
    conceptBody:
        'Porque en cada pasada el algoritmo selecciona al mejor candidato: el menor valor que todavía no está ordenado. Una vez elegido, no vuelve a moverlo nunca más; ya está en su lugar definitivo.',
    conceptExtra:
        'Es uno de los primeros algoritmos que se estudian porque se puede explicar sin trucos: buscar el mínimo y ponerlo al principio, una y otra vez, hasta que no quede nada por ordenar.',
    how:
        'Selection Sort divide el arreglo en una parte ordenada y otra pendiente. En cada recorrido busca el valor mínimo de la parte pendiente y lo intercambia con el primer elemento de esa parte.',
    howExtra:
        'Al principio la parte ordenada está vacía y la pendiente es todo el arreglo. Después de cada pasada la frontera avanza una posición hacia la derecha, de modo que la parte ordenada crece de a un elemento y la pendiente se reduce. Cuando solo queda un elemento pendiente, el arreglo completo está ordenado.',
    analogyTitle: 'Ejemplo cotidiano: ordenar cartas en la mano',
    analogyBody:
        'Imagina que tienes cartas numeradas boca arriba sobre la mesa. Buscas la más pequeña, la pones en la primera posición de tu mano; luego buscas la más pequeña de las que quedan y la pones en la segunda posición, y así hasta terminar. Eso es exactamente lo que hace Selection Sort.',
    steps: [
      (
        '1. Elige una posición',
        'Comienza por el primer lugar que todavía no está ordenado.',
        'Llamemos i a esa posición. Todo lo que está a la izquierda de i ya es definitivo; todo lo que está desde i hacia la derecha sigue pendiente.',
      ),
      (
        '2. Busca el mínimo',
        'Compara todos los elementos restantes y conserva el menor encontrado.',
        'Recorre desde i hasta el final recordando la posición del valor más pequeño visto hasta ahora. Cada vez que aparece uno menor, ese pasa a ser el nuevo mínimo.',
      ),
      (
        '3. Intercambia',
        'Mueve el mínimo a la posición elegida. Repite con la siguiente posición.',
        'Se intercambia el mínimo con el elemento que estaba en i. Si el mínimo ya estaba en i, no hay nada que mover. Luego i avanza una posición y se repite hasta llegar al penúltimo elemento.',
      ),
    ],
    example:
        'Ejemplo: [8, 3, 6, 2] → el mínimo es 2 → se intercambia con 8 → [2, 3, 6, 8].',
    trace: [
      SortingTraceRow('Inicio', '[8, 3, 6, 2]', 'Todo el arreglo está pendiente.'),
      SortingTraceRow(
        'Pasada 1',
        '[2, 3, 6, 8]',
        'El mínimo es 2 (posición 3): se intercambia con el 8 de la posición 0.',
      ),
      SortingTraceRow(
        'Pasada 2',
        '[2, 3, 6, 8]',
        'El mínimo de [3, 6, 8] es 3 y ya está en su lugar.',
      ),
      SortingTraceRow(
        'Pasada 3',
        '[2, 3, 6, 8]',
        'El mínimo de [6, 8] es 6 y ya está en su lugar. Fin.',
      ),
    ],
    complexity: 'n(n - 1) / 2 ≈ n² / 2',
    complexityDetails:
        'Realiza n(n - 1) / 2 comparaciones, incluso si los datos ya estaban ordenados. Complejidad temporal: O(n²).',
    complexityExtra:
        'Su comportamiento es muy predecible: siempre hace la misma cantidad de comparaciones sin importar el orden inicial. En cambio, el número de intercambios es pequeño (como máximo n - 1), lo que lo vuelve útil cuando mover datos es costoso.',
    metrics: [
      ('Mejor caso', 'O(n²)'),
      ('Caso promedio', 'O(n²)'),
      ('Peor caso', 'O(n²)'),
      ('Espacio extra', 'O(1)'),
      ('Intercambios', 'máx. n - 1'),
      ('Estable', 'No'),
    ],
    pros: [
      'Muy fácil de entender e implementar.',
      'Hace pocos intercambios: como máximo n - 1.',
      'Ordena in situ, sin memoria adicional.',
      'Su tiempo es predecible, no depende del orden inicial.',
    ],
    cons: [
      'Siempre cuesta O(n²), aunque los datos ya estén ordenados.',
      'No aprovecha el orden parcial que ya exista.',
      'No es estable: puede alterar el orden de elementos iguales.',
      'Poco práctico para conjuntos de datos grandes.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Es una buena opción para listas pequeñas, para enseñar cómo funciona un ordenamiento y cuando escribir en memoria es mucho más caro que leer (por ejemplo, memorias flash). Para grandes volúmenes de datos es preferible un algoritmo de tipo n log n.',
    cta:
        'Observa cómo el mínimo viaja a su posición definitiva y cuenta las comparaciones en tiempo real.',
    videos: [
      SortingVideo(
        title: 'Video 1: Selection Sort paso a paso',
        description:
            'Explicación en español con prueba de escritorio: sigue cómo cambian las posiciones en cada pasada.',
        url: 'https://www.youtube.com/watch?v=wJzJIX0CYI0',
        label: 'Prueba de escritorio',
      ),
      SortingVideo(
        title: 'Video 2: la idea del ordenamiento por selección',
        description:
            'Una introducción clara al concepto, ideal para repasar antes de probar el laboratorio.',
        url: 'https://www.youtube.com/watch?v=Myy-eU-SWbE',
        label: 'Introducción',
      ),
      SortingVideo(
        title: 'Video 3: Selection Sort bailado',
        description:
            'Una forma distinta y memorable de ver cómo se elige el mínimo y se intercambia.',
        url: 'https://www.youtube.com/watch?v=Ns4TPTC8whw',
        label: 'Visualización con baile',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // INSERTION SORT
  // ---------------------------------------------------------------------------
  static const _insertion = SortingPageContent(
    badge: 'Ordenamiento por inserción',
    badgeIcon: Icons.low_priority_rounded,
    heroIcon: Icons.low_priority_rounded,
    intro:
        'Toma cada elemento y ubícalo en el lugar correcto dentro de la parte ya ordenada.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Por qué se llama "inserción"?',
    conceptBody:
        'Porque en cada paso toma un elemento nuevo y lo inserta en el lugar que le corresponde dentro de la parte que ya está ordenada, desplazando a los mayores un espacio hacia la derecha.',
    conceptExtra:
        'Es el método que usamos de forma natural al ordenar a mano. Su gran ventaja es que se adapta a los datos: si el arreglo ya viene casi ordenado, casi no tiene trabajo que hacer.',
    how:
        'Insertion Sort construye una región ordenada de izquierda a derecha. Extrae el elemento actual, desplaza a la derecha los valores mayores y lo inserta en el espacio que queda.',
    howExtra:
        'El primer elemento se considera ordenado por sí solo. Luego se toma el segundo, el tercero, y así sucesivamente: cada uno (la "clave") se compara hacia la izquierda con los elementos ya ordenados. Los que son mayores se corren un lugar a la derecha para abrir un hueco, y la clave cae en ese hueco.',
    analogyTitle: 'Ejemplo cotidiano: ordenar cartas de una baraja',
    analogyBody:
        'Cuando repartes cartas y las vas tomando una por una, cada carta nueva la colocas en su sitio entre las que ya tienes ordenadas en la mano: la comparas con las anteriores, corres las mayores y la insertas. Eso es Insertion Sort.',
    steps: [
      (
        '1. Extrae la clave',
        'Toma el siguiente elemento a la derecha de la región ordenada.',
        'La clave se "levanta" temporalmente del arreglo. Todo lo que está a su izquierda ya está ordenado entre sí, aunque todavía no sea la posición definitiva de cada valor.',
      ),
      (
        '2. Desplaza',
        'Compara hacia la izquierda y mueve una posición a la derecha cada valor mayor.',
        'Se avanza hacia la izquierda comparando la clave con cada elemento ordenado. Mientras el elemento comparado sea mayor que la clave, se corre una posición a la derecha. Se detiene al encontrar uno menor o igual, o al llegar al inicio.',
      ),
      (
        '3. Inserta',
        'Coloca la clave en el espacio libre y amplía la región ordenada.',
        'El hueco que quedó libre es justo el lugar que le corresponde a la clave. Al colocarla ahí, la región ordenada crece en un elemento y se pasa a la siguiente clave.',
      ),
    ],
    example:
        'Ejemplo: [3, 7, 4, 9] → la clave es 4 → 7 se desplaza → [3, 4, 7, 9].',
    trace: [
      SortingTraceRow('Inicio', '[3, 7, 4, 9]', 'La región ordenada es solo [3].'),
      SortingTraceRow(
        'Clave 7',
        '[3, 7, 4, 9]',
        '3 es menor que 7, así que 7 se queda donde está.',
      ),
      SortingTraceRow(
        'Clave 4',
        '[3, 4, 7, 9]',
        '7 es mayor que 4 y se desplaza a la derecha; 3 es menor, así que 4 se inserta ahí.',
      ),
      SortingTraceRow(
        'Clave 9',
        '[3, 4, 7, 9]',
        '7 es menor que 9: no hay desplazamientos. Fin.',
      ),
    ],
    complexity: 'n² / 4',
    complexityDetails:
        'La aproximación utilizada en la materia es n² / 4. El trabajo depende del orden inicial de los datos; su complejidad temporal es O(n²).',
    complexityExtra:
        'Si el arreglo ya está ordenado, cada clave se compara una sola vez y el costo baja a O(n). Si está en orden inverso, cada clave debe recorrer toda la región ordenada y el costo se acerca al máximo. Por eso se dice que es un algoritmo adaptativo.',
    metrics: [
      ('Mejor caso', 'O(n)'),
      ('Caso promedio', 'O(n²)'),
      ('Peor caso', 'O(n²)'),
      ('Espacio extra', 'O(1)'),
      ('Adaptativo', 'Sí'),
      ('Estable', 'Sí'),
    ],
    pros: [
      'Muy rápido en datos casi ordenados (mejor caso O(n)).',
      'Es estable: respeta el orden de elementos iguales.',
      'Ordena in situ, sin memoria adicional.',
      'Puede ordenar a medida que llegan los datos.',
    ],
    cons: [
      'Cuesta O(n²) en promedio y en el peor caso.',
      'Mueve muchos elementos de a una posición a la vez.',
      'Es lento con arreglos grandes y desordenados.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Funciona muy bien con listas pequeñas y con datos que ya vienen casi ordenados. Por eso muchas implementaciones profesionales lo usan como paso final o para tramos cortos dentro de algoritmos más rápidos.',
    cta:
        'Mira cómo la clave se eleva, los mayores se desplazan y el hueco se llena con el valor correcto.',
    videos: [
      SortingVideo(
        title: 'Video 1: Insertion Sort paso a paso',
        description:
            'Explicación en español con prueba de escritorio del ordenamiento por inserción.',
        url: 'https://www.youtube.com/watch?v=8rhtmJ7nurM',
        label: 'Prueba de escritorio',
      ),
      SortingVideo(
        title: 'Video 2: explicación, pseudocódigo y complejidad',
        description:
            'Cubre la idea general, el pseudocódigo y el análisis de complejidad con un visualizador.',
        url: 'https://www.youtube.com/watch?v=6GU6AGEWYJY',
        label: 'Teoría y código',
      ),
      SortingVideo(
        title: 'Video 3: Insertion Sort bailado',
        description:
            'Observa cómo cada elemento se inserta en la fila ordenada mediante una coreografía.',
        url: 'https://www.youtube.com/watch?v=ROalU379l3U',
        label: 'Visualización con baile',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // SHELL SORT
  // ---------------------------------------------------------------------------
  static const _shell = SortingPageContent(
    badge: 'Inserción con saltos',
    badgeIcon: Icons.space_bar_rounded,
    heroIcon: Icons.space_bar_rounded,
    intro:
        'Ordena elementos distantes entre sí; reduce el gap hasta llegar a una inserción final con gap 1.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Qué es el "gap"?',
    conceptBody:
        'El gap es la distancia entre los elementos que se comparan en cada pasada. Con un gap grande, los valores mueven grandes distancias de un solo salto; con gap 1 el algoritmo se comporta como una inserción normal.',
    conceptExtra:
        'Shell Sort fue propuesto por Donald Shell en 1959. Su truco es que Insertion Sort es muy rápido con datos casi ordenados, así que primero "casi ordena" el arreglo con saltos grandes y deja la inserción fina para el final.',
    how:
        'Shell Sort aplica inserción a subsecuencias separadas por incrementos de Knuth (1, 4, 13, …). Cada pasada reduce el gap; la última, con gap 1, termina de ordenar.',
    howExtra:
        'La secuencia de Knuth sigue la regla h = 3h + 1 (1, 4, 13, 40, …). Se elige el mayor gap que sea razonable para el tamaño del arreglo y se va reduciendo. Cada pasada deja al arreglo "h-ordenado": los elementos separados por h posiciones ya quedan en orden relativo, lo que prepara el terreno para la pasada siguiente.',
    analogyTitle: 'Ejemplo cotidiano: ordenar una fila de personas por estatura',
    analogyBody:
        'En vez de pedir que vecinos contiguos se intercambien, primero haces que personas muy separadas en la fila se comparen y se cambien de lugar. Así los más altos viajan rápido hacia el final y los más bajos al inicio. Luego acortas la distancia hasta que solo corriges ajustes pequeños entre vecinos.',
    steps: [
      (
        '1. Calcula el gap',
        'Usa el mayor incremento de Knuth apropiado para el tamaño.',
        'Se parte de gap = 1 y se multiplica por 3 sumando 1 mientras el gap siga siendo pequeño respecto al tamaño del arreglo. Para pocos elementos el gap inicial puede ser 1 o muy cercano.',
      ),
      (
        '2. Ordena subsecuencias',
        'Compara elementos separados por el gap y desplaza los mayores.',
        'Los elementos que están a gap posiciones entre sí forman subsecuencias independientes. Cada una se ordena con inserción: se toma una clave, se compara con el elemento que está gap lugares atrás y se desplaza si es mayor.',
      ),
      (
        '3. Reduce el gap',
        'Repite hasta completar una pasada con gap 1.',
        'Tras cada pasada se pasa al siguiente gap menor de la secuencia (por ejemplo 13 → 4 → 1). La pasada final con gap 1 es una inserción clásica, pero sobre un arreglo que ya está casi ordenado, así que termina muy rápido.',
      ),
    ],
    example:
        'Ejemplo: [8, 3, 6, 2] → gap 1 → inserción con desplazamientos → [2, 3, 6, 8].',
    trace: [
      SortingTraceRow(
        'Arreglo',
        '[8, 3, 6, 2, 7, 1, 5, 4]',
        'Ejemplo más grande para ver el efecto de un gap mayor que 1.',
      ),
      SortingTraceRow(
        'Gap 4',
        '[7, 1, 5, 2, 8, 3, 6, 4]',
        'Se comparan las parejas (8,7), (3,1), (6,5) y (2,4): las tres primeras se intercambian.',
      ),
      SortingTraceRow(
        'Gap 1',
        '[1, 2, 3, 4, 5, 6, 7, 8]',
        'Inserción final sobre un arreglo casi ordenado: pocos desplazamientos. Fin.',
      ),
    ],
    complexity: 'Θ(n³ᐟ²) peor caso',
    complexityDetails:
        'Con incrementos de Knuth, el peor caso es Θ(n³ᐟ²). Se ordena in situ; las comparaciones y desplazamientos reales se muestran en el laboratorio.',
    complexityExtra:
        'La complejidad exacta de Shell Sort depende de la secuencia de gaps elegida: con la secuencia original de Shell (n/2, n/4, …) el peor caso es O(n²), mientras que con la de Knuth baja a Θ(n³ᐟ²). En la práctica suele ser mucho más rápido que Insertion Sort sin necesitar memoria adicional.',
    metrics: [
      ('Mejor caso', 'O(n log n)'),
      ('Caso promedio', 'según el gap'),
      ('Peor caso (Knuth)', 'Θ(n³ᐟ²)'),
      ('Espacio extra', 'O(1)'),
      ('Adaptativo', 'Sí'),
      ('Estable', 'No'),
    ],
    pros: [
      'Mucho más rápido que la inserción simple en arreglos medianos.',
      'Ordena in situ, sin memoria adicional.',
      'Es fácil de implementar a partir de la inserción.',
      'Aprovecha el orden parcial gracias a las pasadas con gap.',
    ],
    cons: [
      'Su rendimiento depende de la secuencia de gaps elegida.',
      'No es estable: los saltos pueden alterar elementos iguales.',
      'Su análisis teórico es más difícil que el de otros métodos.',
      'Para datos muy grandes hay algoritmos n log n garantizados.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Es una mejora sencilla cuando se quiere algo más rápido que la inserción sin recurrir a recursión ni a memoria extra. Se usa en sistemas embebidos y en situaciones donde importa un código pequeño y un uso mínimo de memoria.',
    cta:
        'Observa cómo cambia el gap en cada pasada y cómo los elementos lejanos se acercan a su lugar.',
    videos: [
      SortingVideo(
        title: 'Video 1: Shell Sort paso a paso',
        description:
            'Explicación en español con prueba de escritorio, útil para seguir cada gap.',
        url: 'https://www.youtube.com/watch?v=vwn514rBtNc',
        label: 'Prueba de escritorio',
      ),
      SortingVideo(
        title: 'Video 2: funcionamiento gráfico del método Shell',
        description:
            'Describe gráficamente cómo se agrupan y ordenan los elementos según el incremento.',
        url: 'https://www.youtube.com/watch?v=9GAtGHVRYh0',
        label: 'Explicación gráfica',
      ),
      SortingVideo(
        title: 'Video 3: Shell Sort bailado',
        description:
            'Una coreografía que muestra cómo los saltos grandes se reducen hasta llegar a gap 1.',
        url: 'https://www.youtube.com/watch?v=CmPA7zE8mx0',
        label: 'Visualización con baile',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // MERGE SORT
  // ---------------------------------------------------------------------------
  static const _merge = SortingPageContent(
    badge: 'Divide y vencerás',
    badgeIcon: Icons.call_merge_rounded,
    heroIcon: Icons.call_merge_rounded,
    intro:
        'Divide el conjunto en dos mitades, ordena cada mitad y fusiónalas comparando sus elementos.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Qué significa "divide y vencerás"?',
    conceptBody:
        'Es una estrategia que parte un problema grande en problemas más pequeños de la misma forma, los resuelve por separado y combina las respuestas. Ordenar una lista de un solo elemento es trivial: ya está ordenada.',
    conceptExtra:
        'Merge Sort fue propuesto por John von Neumann en 1945. Su secreto es que fusionar dos listas que ya están ordenadas es muy barato: basta con mirar el primer elemento pendiente de cada una y quedarse con el menor.',
    how:
        'Merge Sort divide recursivamente en dos mitades hasta obtener tramos de un elemento. Después fusiona cada par de mitades ya ordenadas, eligiendo el menor elemento disponible.',
    howExtra:
        'El algoritmo tiene dos fases. En la de división se parte el arreglo por la mitad una y otra vez hasta llegar a tramos de tamaño 1. En la de fusión se recorre el camino de vuelta: cada par de tramos ordenados se combina en uno más grande y ordenado, hasta reconstruir el arreglo completo.',
    analogyTitle: 'Ejemplo cotidiano: unir dos montones de exámenes',
    analogyBody:
        'Dos profesores corrigen cada uno la mitad de los exámenes y los dejan ordenados por nota. Para juntarlos en un solo montón ordenado, basta con mirar el examen de arriba de cada pila y pasar siempre el de menor nota. Merge Sort aplica esa misma idea una y otra vez.',
    steps: [
      (
        '1. Divide',
        'Separa el tramo en mitades hasta llegar a elementos individuales.',
        'Se calcula el punto medio y se parte el tramo en una mitad izquierda y otra derecha. El proceso se repite sobre cada mitad hasta que cada tramo tenga un solo elemento, que por definición ya está ordenado.',
      ),
      (
        '2. Ordena ambas mitades',
        'Resuelve primero la mitad izquierda y después la derecha.',
        'La recursión se encarga: se llama al mismo algoritmo sobre la mitad izquierda y luego sobre la derecha. Cuando ambas terminan, se tienen dos tramos ordenados listos para unirse.',
      ),
      (
        '3. Fusiona',
        'Compara sus primeros elementos pendientes y escribe el menor en la salida.',
        'Se usan dos punteros, uno por tramo. Se compara el elemento apuntado en cada uno, se copia el menor al resultado y se avanza ese puntero. Cuando un tramo se agota, se copia lo que queda del otro.',
      ),
    ],
    example:
        'Ejemplo: [8, 3, 6, 2] → [3, 8] y [2, 6] → fusión → [2, 3, 6, 8].',
    trace: [
      SortingTraceRow('Inicio', '[8, 3, 6, 2]', 'Un solo tramo de 4 elementos.'),
      SortingTraceRow(
        'División',
        '[8, 3]  |  [6, 2]',
        'Se parte en dos mitades y cada una se vuelve a dividir hasta quedar en elementos sueltos.',
      ),
      SortingTraceRow(
        'Fusión pequeña',
        '[3, 8]  |  [2, 6]',
        'Cada pareja se fusiona ordenada: 3 antes que 8, y 2 antes que 6.',
      ),
      SortingTraceRow(
        'Fusión final',
        '[2, 3, 6, 8]',
        'Se compara 3 con 2 (sale 2), 3 con 6 (sale 3), 8 con 6 (sale 6) y finalmente sale 8.',
      ),
    ],
    complexity: 'Θ(n log n)',
    complexityDetails:
        'Divide y fusiona en Θ(n log n) tiempo incluso en el peor caso. La fusión requiere Θ(n) espacio auxiliar.',
    complexityExtra:
        'El arreglo se divide en log n niveles y en cada nivel se recorren los n elementos para fusionar, de ahí n log n. Es una de las pocas opciones con tiempo garantizado en todos los casos, a cambio de usar memoria adicional proporcional al tamaño de los datos.',
    metrics: [
      ('Mejor caso', 'Θ(n log n)'),
      ('Caso promedio', 'Θ(n log n)'),
      ('Peor caso', 'Θ(n log n)'),
      ('Espacio extra', 'Θ(n)'),
      ('Recursivo', 'Sí'),
      ('Estable', 'Sí'),
    ],
    pros: [
      'Tiempo garantizado Θ(n log n) en todos los casos.',
      'Es estable: respeta el orden de elementos iguales.',
      'Escala muy bien a conjuntos de datos grandes.',
      'Ideal para listas enlazadas y datos externos.',
    ],
    cons: [
      'Necesita Θ(n) de memoria auxiliar para fusionar.',
      'Es más complejo de implementar que los métodos cuadráticos.',
      'Para arreglos muy pequeños suele ser más lento que la inserción.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Es la elección habitual cuando se necesita un tiempo predecible con muchos datos o cuando la estabilidad importa. Se usa, por ejemplo, para ordenar archivos que no caben en memoria y como base de los ordenamientos estándar de varios lenguajes.',
    cta:
        'Sigue cómo se dividen los tramos y cómo la fusión elige siempre el menor elemento disponible.',
    videos: [
      SortingVideo(
        title: 'Video 1: Merge Sort explicado',
        description:
            'Introducción al ordenamiento por mezcla como ejemplo clásico del patrón divide y vencerás.',
        url: 'https://www.youtube.com/watch?v=ACFZn_xQcz8',
        label: 'Explicación principal',
      ),
      SortingVideo(
        title: 'Video 2: Merge Sort bailado',
        description:
            'Una coreografía que muestra cómo se dividen los grupos y cómo se fusionan de forma ordenada.',
        url: 'https://youtu.be/XaqR3G_NVoo',
        label: 'Visualización con baile',
      ),
    ],
  );
}