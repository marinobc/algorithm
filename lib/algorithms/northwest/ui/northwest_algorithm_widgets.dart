import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../../../domain/models/nodo.dart';
import '../../../ui/widgets/base_algorithm_card.dart';
import '../domain/models/northwest_models.dart';
import '../domain/services/northwest_problem_extractor.dart';
import '../providers/northwest_provider.dart';
import 'northwest_details_screen.dart';
import 'northwest_matrix_screen.dart';

class NorthwestLaunchButton extends ConsumerWidget {
  final VoidCallback onPressed;

  const NorthwestLaunchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.local_shipping_outlined),
      label: const Text('Abrir Esquina Noroeste'),
    );
  }
}

class NorthwestEmptyState extends StatelessWidget {
  const NorthwestEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_chart_outlined, size: 58, color: colors.primary),
              const SizedBox(height: 18),
              Text(
                'Configura tu problema de transporte',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Define los origenes, destinos, costos, ofertas y demandas para generar automaticamente la red.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => NorthwestMatrixScreen.open(context),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Ingresar datos de transporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NorthwestCanvasControls extends ConsumerWidget {
  const NorthwestCanvasControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(grafoProvider);
    final selectedRole = ref.watch(northwestActiveRoleProvider);
    final originCount = graph.nodos.values
        .where((node) => node.rol == NorthwestRoles.origin)
        .length;
    final destinationCount = graph.nodos.values
        .where((node) => node.rol == NorthwestRoles.destination)
        .length;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nuevo nodo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: NorthwestRoles.origin,
                  icon: const Icon(Icons.inventory_2_outlined, size: 17),
                  label: Text('Origen ($originCount)'),
                ),
                ButtonSegment(
                  value: NorthwestRoles.destination,
                  icon: const Icon(Icons.flag_outlined, size: 17),
                  label: Text('Destino ($destinationCount)'),
                ),
              ],
              selected: {selectedRole},
              onSelectionChanged: (selection) => ref
                  .read(northwestActiveRoleProvider.notifier)
                  .setRole(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}

class NorthwestQuantityEditor extends ConsumerStatefulWidget {
  final Nodo node;

  const NorthwestQuantityEditor({super.key, required this.node});

  @override
  ConsumerState<NorthwestQuantityEditor> createState() =>
      _NorthwestQuantityEditorState();
}

class _NorthwestQuantityEditorState
    extends ConsumerState<NorthwestQuantityEditor> {
  late final TextEditingController _controller;
  String? _error;

  bool get _isOrigin => widget.node.rol == NorthwestRoles.origin;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatNumber(widget.node.cantidad ?? 0),
    );
  }

  @override
  void didUpdateWidget(covariant NorthwestQuantityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id ||
        oldWidget.node.cantidad != widget.node.cantidad) {
      _controller.text = _formatNumber(widget.node.cantidad ?? 0);
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || !value.isFinite || value < 0) {
      setState(() => _error = 'Ingresa un numero no negativo.');
      return;
    }
    ref
        .read(grafoProvider.notifier)
        .actualizarNodo(widget.node.id, cantidad: value);
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    setState(() {
      _controller.text = _formatNumber(value);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: _isOrigin ? 'Oferta / disponibilidad' : 'Demanda',
          errorText: _error,
          prefixIcon: Icon(
            _isOrigin ? Icons.inventory_2_outlined : Icons.flag_outlined,
          ),
          suffixIcon: IconButton(
            tooltip: 'Guardar cantidad',
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
          ),
        ),
        onTap: () => _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        ),
        onSubmitted: (_) => _save(),
      ),
    );
  }
}

class NorthwestAlgorithmCard extends ConsumerWidget {
  const NorthwestAlgorithmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(northwestResultProvider);
    final problem = ref.watch(northwestProblemProvider);
    if (result == null || problem == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return BaseAlgorithmCard(
      title: 'Esquina Noroeste / MODI',
      icon: Icons.local_shipping_outlined,
      onClose: () =>
          ref.read(northwestNotifierProvider.notifier).setActive(false),
      resultBanner: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              problem.objective == TransportationObjective.minimize
                  ? 'Costo minimo (Z)'
                  : 'Beneficio maximo (Z)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Z = ${_formatNumber(result.objectiveValue)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inicial: ${_formatNumber(result.initialObjectiveValue)}  |  '
            'Iteraciones: ${result.iterations.length - 1}',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NorthwestDetailsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 16),
              label: const Text(
                'Mostrar solución',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
