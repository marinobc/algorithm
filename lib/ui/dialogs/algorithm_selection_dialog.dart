import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/domain/services/assignment_validator.dart';
import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/core/graph_algorithm.dart';
import '../../algorithms/johnson/domain/services/johnson_validator.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../algorithms/northwest/domain/services/northwest_problem_extractor.dart';
import '../../algorithms/northwest/providers/northwest_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../screens/graph_editor_screen.dart';
import '../screens/welcome_explanation_screen.dart';
import '../widgets/algorithm_catalog_illustration.dart';
import '../widgets/app_toast.dart';

class AlgorithmSelectionDialog extends StatelessWidget {
  final WidgetRef ref;
  final bool canDismiss;

  const AlgorithmSelectionDialog({
    super.key,
    required this.ref,
    this.canDismiss = true,
  });

  static Future<GraphAlgorithm?> show(
    BuildContext context,
    WidgetRef ref, {
    bool canDismiss = true,
  }) {
    return showDialog<GraphAlgorithm?>(
      context: context,
      barrierDismissible: canDismiss,
      builder: (_) =>
          AlgorithmSelectionDialog(ref: ref, canDismiss: canDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registered = {
      for (final algorithm in ref.read(algorithmRegistryProvider))
        algorithm.id: algorithm,
    };
    final options = _options(registered);
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              _CatalogHeader(
                canDismiss: canDismiss,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1040
                        ? 4
                        : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          mainAxisExtent: columns == 1 ? 280 : 300,
                        ),
                        itemBuilder: (context, index) => _AlgorithmCatalogCard(
                          option: options[index],
                          onSelect: options[index].available
                              ? () => _select(context, options[index])
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_AlgorithmCatalogOption> _options(
    Map<String, GraphAlgorithm> registered,
  ) {
    final assignment = registered[AlgorithmRegistry.assignmentId];
    final johnson = registered[AlgorithmRegistry.johnsonId];
    final northwest = registered[AlgorithmRegistry.northwestId];
    return [
      const _AlgorithmCatalogOption(
        id: 'free-mode',
        title: 'Modo Libre',
        description: 'Dibuja y edita grafos libremente, sin restricciones de un algoritmo.',
        accentColor: Color(0xFF8B5CF6),
        illustration: AlgorithmCatalogIllustration.freeMode,
      ),
      if (assignment != null)
        _AlgorithmCatalogOption(
          id: assignment.id,
          title: 'Asignación',
          description:
              'Resuelve problemas de asignación mediante el Algoritmo Húngaro.',
          accentColor: const Color(0xFF258BFF),
          illustration: AlgorithmCatalogIllustration.assignment,
          algorithm: assignment,
        ),
      if (johnson != null)
        _AlgorithmCatalogOption(
          id: johnson.id,
          title: 'Johnson',
          description: 'Analiza redes de actividades, identifica la ruta crítica y calcula las holguras.',
          accentColor: const Color(0xFF00C7A5),
          illustration: AlgorithmCatalogIllustration.johnson,
          algorithm: johnson,
        ),
      if (northwest != null)
        _AlgorithmCatalogOption(
          id: northwest.id,
          title: 'Northwest',
          description: 'Resuelve problemas de transporte mediante esquina noroeste y optimización MODI.',
          accentColor: const Color(0xFFE54872),
          illustration: AlgorithmCatalogIllustration.northwest,
          algorithm: northwest,
        ),
      const _AlgorithmCatalogOption(
        id: 'upcoming',
        title: 'Próximamente',
        description: 'Estamos preparando nuevos algoritmos para ampliar las herramientas disponibles.',
        accentColor: Color(0xFF756A9F),
        illustration: AlgorithmCatalogIllustration.upcoming,
        available: false,
      ),
    ];
  }

  void _select(BuildContext context, _AlgorithmCatalogOption option) {
    if (option.id == 'free-mode') {
      ref.read(activeAlgorithmProvider.notifier).clear();
      ref.read(transportationNotifierProvider.notifier).setActive(false);
      ref.read(johnsonNotifierProvider.notifier).setActive(false);
      ref.read(northwestNotifierProvider.notifier).setActive(false);
      Navigator.of(context).pop(null);
      return;
    }
    final algorithm = option.algorithm;
    if (algorithm == null) return;
    final graph = ref.read(grafoProvider);
    if (graph.conexiones.isNotEmpty) {
      final error = switch (algorithm.id) {
        AlgorithmRegistry.assignmentId => TransportationValidator.validate(
          graph,
        ).errorMessage,
        AlgorithmRegistry.johnsonId => JohnsonValidator.validate(
          graph,
        ).errorMessage,
        AlgorithmRegistry.northwestId => NorthwestProblemExtractor.extract(
          graph,
        ).errorMessage,
        _ => null,
      };
      if (error != null) {
        AppToast.show(context, error, icon: Icons.warning_amber_rounded);
        return;
      }
    }
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    ref.read(activeAlgorithmProvider.notifier).selectById(algorithm.id);
    Navigator.of(context).pop(algorithm);
  }
}

class AlgorithmSelectionScreen extends ConsumerWidget {
  const AlgorithmSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registered = {
      for (final algorithm in ref.read(algorithmRegistryProvider))
        algorithm.id: algorithm,
    };
    final options = AlgorithmSelectionDialog(ref: ref)._options(registered);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  _CatalogHeader(
                    canDismiss: true,
                    onClose: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(false);
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const WelcomeExplanationScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1040
                            ? 4
                            : constraints.maxWidth >= 620
                            ? 2
                            : 1;
                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: options.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  mainAxisExtent: columns == 1 ? 280 : 300,
                                ),
                            itemBuilder: (context, index) =>
                                _AlgorithmCatalogCard(
                                  option: options[index],
                                  onSelect: options[index].available
                                      ? () => _select(
                                          context,
                                          ref,
                                          options[index],
                                        )
                                      : null,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(
    BuildContext context,
    WidgetRef ref,
    _AlgorithmCatalogOption option,
  ) {
    if (option.id == 'free-mode') {
      ref.read(activeAlgorithmProvider.notifier).clear();
    } else {
      final algorithm = option.algorithm;
      if (algorithm == null) return;
      ref.read(activeAlgorithmProvider.notifier).selectById(algorithm.id);
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
      );
    }
  }
}

class _CatalogHeader extends StatelessWidget {
  final bool canDismiss;
  final VoidCallback onClose;
  const _CatalogHeader({required this.canDismiss, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ALGORITMOS',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Selecciona un algoritmo',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Elige el algoritmo con el que quieres trabajar en el editor.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
        if (canDismiss)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cerrar selector de algoritmos',
          ),
      ],
    );
  }
}

class _AlgorithmCatalogCard extends StatefulWidget {
  final _AlgorithmCatalogOption option;
  final VoidCallback? onSelect;
  const _AlgorithmCatalogCard({required this.option, this.onSelect});
  @override
  State<_AlgorithmCatalogCard> createState() => _AlgorithmCatalogCardState();
}

class _AlgorithmCatalogCardState extends State<_AlgorithmCatalogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final available = widget.option.available;
    return Semantics(
      button: available,
      enabled: available,
      label: widget.option.title,
      child: MouseRegion(
        cursor: available ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: available
                    ? (_hovered
                          ? widget.option.accentColor.withValues(alpha: 0.18)
                          : colors.surfaceContainerLow)
                    : colors.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: available
                      ? (_hovered
                            ? widget.option.accentColor
                            : colors.outlineVariant.withValues(alpha: 0.5))
                      : colors.outlineVariant.withValues(alpha: 0.2),
                  width: available && _hovered ? 1.8 : 1.0,
                ),
                boxShadow: _hovered && available
                    ? [
                        BoxShadow(
                          color: widget.option.accentColor.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: available ? 1 : .55,
                      child: AlgorithmCatalogIllustrationWidget(
                        illustration: widget.option.illustration,
                        accentColor: widget.option.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.option.title,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (available)
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: widget.option.accentColor.withValues(
                              alpha: .25,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Próximamente',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.option.accentColor.withValues(
                        alpha: available ? 1 : .45,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlgorithmCatalogOption {
  final String id;
  final String title;
  final String description;
  final Color accentColor;
  final AlgorithmCatalogIllustration illustration;
  final bool available;
  final GraphAlgorithm? algorithm;
  const _AlgorithmCatalogOption({
    required this.id,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.illustration,
    this.available = true,
    this.algorithm,
  });
}
