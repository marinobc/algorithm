import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/services/bst_storage_service.dart';
import '../../../ui/widgets/app_toast.dart';
import '../domain/bst_tree.dart';
import 'bst_saved_dialogs.dart';
import 'bst_tree_canvas.dart';

enum _InputMode { manual, traversals }

class BstLabScreen extends StatefulWidget {
  const BstLabScreen({super.key});

  @override
  State<BstLabScreen> createState() => _BstLabScreenState();
}

class _BstLabScreenState extends State<BstLabScreen> {
  final _manual = TextEditingController();
  final _quantity = TextEditingController(text: '8');
  final _first = TextEditingController();
  final _second = TextEditingController();
  final _random = Random();
  BstTree _tree = const BstTree.empty();
  _InputMode _mode = _InputMode.manual;
  BstTraversal _firstType = BstTraversal.preorder;
  BstTraversal _secondType = BstTraversal.inorder;
  String? _manualError;
  String? _reconstructionError;
  String? _quantityError;
  String? _savedJson;
  String _lastManualText = '';
  List<int> _manualSequence = const [];
  List<int> _path = const [];

  @override
  void dispose() {
    _manual.dispose();
    _quantity.dispose();
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _tree.toJson() != (_savedJson ?? const BstTree.empty().toJson()) ||
      (_tree.isEmpty &&
          (_manual.text.trim().isNotEmpty ||
              _first.text.trim().isNotEmpty ||
              _second.text.trim().isNotEmpty));

  Future<bool> _confirmReplacement(String title) async {
    if (!_hasUnsavedChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: const Text(
              'Los cambios no guardados del árbol actual se perderán.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _applyTree(BstTree tree, {List<int> path = const []}) {
    setState(() {
      _tree = tree;
      _path = path;
      _manualError = null;
      _reconstructionError = null;
    });
  }

  void _onManualChanged(String value) {
    final pasted = value.length - _lastManualText.length > 1;
    _lastManualText = value;
    if (!pasted &&
        _manual.selection.isValid &&
        _manual.selection.baseOffset < value.length) {
      return;
    }
    final complete =
        pasted || value.isEmpty || RegExp(r'[\s,]$').hasMatch(value);
    final source = complete
        ? value
        : value.substring(0, value.lastIndexOf(RegExp(r'[\s,]')) + 1);
    _readManual(source);
  }

  void _readManual(String source) {
    try {
      final values = BstTree.parseValues(source);
      if (_sameSequence(values, _manualSequence)) {
        if (_manualError != null) setState(() => _manualError = null);
        return;
      }
      final old = _tree.traverse(BstTraversal.preorder);
      final path = values.length == old.length + 1 && _samePrefix(values, old)
          ? [..._tree.insertionPath(values.last), values.last]
          : <int>[];
      final next = BstTree.fromValues(values);
      _manualSequence = List<int>.unmodifiable(values);
      _applyTree(next, path: path);
    } on FormatException catch (error) {
      setState(() => _manualError = error.message);
    }
  }

  bool _samePrefix(List<int> values, List<int> old) {
    for (var i = 0; i < old.length; i++) {
      if (values[i] != old[i]) return false;
    }
    return true;
  }

  bool _sameSequence(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    return _samePrefix(first, second);
  }

  Future<void> _generate() async {
    final count = int.tryParse(_quantity.text.trim());
    if (count == null || count < 1) {
      setState(() => _quantityError = 'Ingresa una cantidad mayor que cero.');
      return;
    }
    if (!_tree.isEmpty && !await _confirmReplacement('Generar otro árbol')) {
      return;
    }
    if (!mounted) return;
    final values = List.generate(count, (_) => _random.nextInt(99) + 1);
    final tree = BstTree.fromValues(values);
    _manual.text = '${values.join(', ')}, ';
    _lastManualText = _manual.text;
    _manualSequence = List<int>.unmodifiable(values);
    setState(() => _quantityError = null);
    _applyTree(tree);
    AppToast.show(
      context,
      'Árbol generado con $count valores.',
      icon: Icons.account_tree_rounded,
    );
  }

  void _reconstruct() {
    try {
      final first = BstTree.parseValues(_first.text);
      final second = BstTree.parseValues(_second.text);
      if (first.isEmpty || second.isEmpty) {
        throw const FormatException(
          'Ingresa los dos recorridos para reconstruir.',
        );
      }
      final tree = BstTree.reconstruct(
        firstType: _firstType,
        first: first,
        secondType: _secondType,
        second: second,
      );
      _manual.text = '${tree.traverse(BstTraversal.preorder).join(', ')}, ';
      _lastManualText = _manual.text;
      _manualSequence = List<int>.unmodifiable(
        tree.traverse(BstTraversal.preorder),
      );
      _applyTree(tree);
      AppToast.show(
        context,
        'BST reconstruido correctamente.',
        icon: Icons.account_tree_rounded,
      );
    } on FormatException catch (error) {
      setState(() => _reconstructionError = error.message);
    }
  }

  Future<void> _newTree() async {
    if (!await _confirmReplacement('Nuevo árbol')) return;
    _manual.clear();
    _first.clear();
    _second.clear();
    _lastManualText = '';
    _manualSequence = const [];
    _savedJson = null;
    _applyTree(const BstTree.empty());
  }

  Future<void> _saveTree() async {
    final name = await BstSavedDialogs.askName(context);
    if (name == null || !mounted) return;
    try {
      final saved = await BstStorageService.save(
        SavedBstPractice(
          id: '',
          name: name,
          treeJson: _tree.toJson(),
          manualText: _manual.text,
          quantity: _quantity.text,
          firstText: _first.text,
          secondText: _second.text,
          mode: _mode.name,
          firstType: _firstType.name,
          secondType: _secondType.name,
          savedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => _savedJson = _tree.toJson());
      AppToast.show(
        context,
        'Árbol guardado como ${saved.name}.',
        icon: Icons.save_outlined,
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          'No se pudo guardar el árbol.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _loadTree() async {
    try {
      final saved = await BstSavedDialogs.load(context);
      if (saved == null || !mounted) return;
      final loaded = saved.tree;
      if (!await _confirmReplacement('Cargar otro árbol') || !mounted) return;
      _manual.text = saved.manualText;
      _quantity.text = saved.quantity;
      _first.text = saved.firstText;
      _second.text = saved.secondText;
      _lastManualText = _manual.text;
      _manualSequence = List<int>.unmodifiable(
        BstTree.parseValues(saved.manualText),
      );
      _mode = _InputMode.values.byName(saved.mode);
      _firstType = BstTraversal.values.byName(saved.firstType);
      _secondType = BstTraversal.values.byName(saved.secondType);
      _savedJson = loaded.toJson();
      _applyTree(loaded);
      AppToast.show(
        context,
        'Árbol ${saved.name} cargado.',
        icon: Icons.folder_open_outlined,
      );
    } on FormatException catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          error.message,
          icon: Icons.error_outline_rounded,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          'No se pudo cargar el árbol guardado.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _showGuide() {
    showDialog<void>(
      context: context,
      builder: (context) => const _BstGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 760;
    Widget action(String label, IconData icon, VoidCallback? onPressed) =>
        compact
        ? IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon))
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          );
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerHigh,
        title: Text(
          'Árboles BST',
          style: TextStyle(fontSize: compact ? 17 : 20),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          tooltip: 'Volver a la teoría',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          action('Nuevo', Icons.note_add_outlined, _newTree),
          action('Cargar', Icons.folder_open_outlined, _loadTree),
          action(
            'Guardar',
            Icons.save_outlined,
            _tree.isEmpty ? null : _saveTree,
          ),
          action('Guía de uso', Icons.help_outline_rounded, _showGuide),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;
          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 310, child: _sidePanel(_inputPanel())),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _board(),
                  ),
                ),
                SizedBox(width: 270, child: _sidePanel(_resultsPanel())),
              ],
            );
          }
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (constraints.maxWidth >= 700)
                        SizedBox(
                          height: 560,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 285,
                                child: _sidePanel(_inputPanel()),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _board()),
                            ],
                          ),
                        )
                      else ...[
                        _inputPanel(),
                        const SizedBox(height: 16),
                        SizedBox(height: 420, child: _board()),
                      ],
                      const SizedBox(height: 16),
                      _resultsPanel(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sidePanel(Widget child) => SingleChildScrollView(
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );

  Widget _inputPanel() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeading(Icons.input_rounded, 'Entrada de datos'),
        const SizedBox(height: 16),
        SegmentedButton<_InputMode>(
          segments: const [
            ButtonSegment(value: _InputMode.manual, label: Text('Manual')),
            ButtonSegment(
              value: _InputMode.traversals,
              label: Text('Recorridos'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) =>
              setState(() => _mode = selection.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 18),
        if (_mode == _InputMode.manual) ...[
          Text(
            'Inserción manual',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manual,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Valores',
              hintText: '5, 3, 7, 1, 4',
              border: const OutlineInputBorder(),
              errorText: _manualError,
              helperText: 'Separa con coma, espacio o Enter.',
            ),
            onChanged: _onManualChanged,
            onTapOutside: (_) => _readManual(_manual.text),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _readManual(_manual.text),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Confirmar valores'),
          ),
          const SizedBox(height: 28),
          Text(
            'Generación aleatoria',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    errorText: _quantityError,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Generar árbol aleatorio',
                onPressed: _generate,
                icon: const Icon(Icons.casino_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Valores entre 1 y 99; pueden repetirse.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ] else ...[
          Text(
            'Reconstruir por recorridos',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa dos secuencias del mismo árbol.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _traversalInput(
            _first,
            _firstType,
            (type) => setState(() {
              _firstType = type;
              if (_secondType == type) {
                _secondType = BstTraversal.values.firstWhere(
                  (item) => item != type,
                );
              }
            }),
            BstTraversal.values,
          ),
          const SizedBox(height: 16),
          _traversalInput(
            _second,
            _secondType,
            (type) => setState(() => _secondType = type),
            BstTraversal.values.where((item) => item != _firstType).toList(),
          ),
          if (_reconstructionError != null) ...[
            const SizedBox(height: 10),
            Text(
              _reconstructionError!,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _reconstruct,
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Reconstruir árbol'),
          ),
        ],
      ],
    );
  }

  Widget _traversalInput(
    TextEditingController controller,
    BstTraversal selected,
    ValueChanged<BstTraversal> onChanged,
    List<BstTraversal> options,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<BstTraversal>(
        key: ValueKey(
          '${selected.name}-${options.map((item) => item.name).join()}',
        ),
        initialValue: selected,
        decoration: const InputDecoration(
          labelText: 'Tipo de recorrido',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final type in options)
            DropdownMenuItem(value: type, child: Text(type.label)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: '${selected.label}: valores',
          hintText: '5, 3, 1, 4, 7',
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) {
          if (_reconstructionError != null) {
            setState(() => _reconstructionError = null);
          }
        },
      ),
    ],
  );

  Widget _board() {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pizarra BST',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${_tree.distinctCount} ${_tree.distinctCount == 1 ? 'nodo' : 'nodos'}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: BstTreeCanvas(tree: _tree, insertionPath: _path),
          ),
          if (!_tree.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 10),
              child: Text(
                'Raíz: ${_tree.root!.value}   ·   Altura: ${_tree.height}   ·   Valores: ${_tree.totalCount}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultsPanel() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeading(Icons.format_list_numbered_rounded, 'Recorridos'),
        const SizedBox(height: 8),
        Text(
          'Los valores repetidos aparecen según su frecuencia.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 18),
        for (final type in BstTraversal.values) ...[
          Text(
            type.label,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(switch (type) {
            BstTraversal.preorder => 'Raíz → izquierda → derecha',
            BstTraversal.inorder => 'Izquierda → raíz → derecha',
            BstTraversal.postorder => 'Izquierda → derecha → raíz',
          }, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          SelectableText(
            _tree.isEmpty ? 'Sin valores' : _tree.traverse(type).join(' → '),
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 18),
          if (type != BstTraversal.postorder)
            Divider(color: colors.outlineVariant),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _panelHeading(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

class _BstGuideDialog extends StatelessWidget {
  const _BstGuideDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline_rounded),
          SizedBox(width: 10),
          Text('Guía de uso'),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _item(
                context,
                '1 · Insertar',
                'Escribe 5, 3, 7, 1. Cada coma, espacio o Enter confirma el valor anterior. Usa “Confirmar valores” para el último número. El primero será la raíz.',
              ),
              _item(
                context,
                '2 · Generar',
                'Elige una cantidad y pulsa el dado. Los valores repetidos comparten nodo y muestran su frecuencia ×N.',
              ),
              _item(
                context,
                '3 · Reconstruir',
                'Cambia a Recorridos, elige dos tipos diferentes e introduce ambas secuencias. Por ejemplo, Preorder 5, 3, 7 e Inorder 3, 5, 7.',
              ),
              _item(
                context,
                '4 · Leer recorridos',
                'Preorder visita primero la raíz; Inorder da las claves ordenadas; Postorder deja la raíz al final. Cada frecuencia se repite en el resultado.',
              ),
              _item(
                context,
                '5 · Archivos y vista',
                'Nuevo limpia la práctica; Guardar conserva el árbol en este navegador y Cargar recupera uno guardado. Usa +, − y centrar para explorar árboles grandes.',
              ),
              Text(
                'Las claves menores van a la izquierda y las mayores a la derecha.',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}
