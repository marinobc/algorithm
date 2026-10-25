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
  String? _reconstructionMessage;
  String? _quantityError;
  String? _savedJson;
  String? _savedManualText;
  String? _savedQuantity;
  String? _savedFirstText;
  String? _savedSecondText;
  _InputMode? _savedMode;
  BstTraversal? _savedFirstType;
  BstTraversal? _savedSecondType;
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

  bool get _hasUnsavedChanges {
    if (_savedJson == null) {
      return !_tree.isEmpty ||
          _manual.text.trim().isNotEmpty ||
          _first.text.trim().isNotEmpty ||
          _second.text.trim().isNotEmpty;
    }
    return _tree.toJson() != _savedJson ||
        _manual.text != _savedManualText ||
        _quantity.text != _savedQuantity ||
        _first.text != _savedFirstText ||
        _second.text != _savedSecondText ||
        _mode != _savedMode ||
        _firstType != _savedFirstType ||
        _secondType != _savedSecondType;
  }

  void _captureSavedInputs() {
    _savedManualText = _manual.text;
    _savedQuantity = _quantity.text;
    _savedFirstText = _first.text;
    _savedSecondText = _second.text;
    _savedMode = _mode;
    _savedFirstType = _firstType;
    _savedSecondType = _secondType;
  }

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
      _reconstructionMessage = null;
    });
  }

  void _onManualChanged(String value) {
    final lengthChange = value.length - _lastManualText.length;
    final hasSeparator = RegExp(r'[\s,]').hasMatch(value);
    final pasted = lengthChange > 1 || (lengthChange < -1 && hasSeparator);
    _lastManualText = value;
    if (_manualError != null) {
      setState(() => _manualError = null);
    }
    if (pasted || value.isEmpty) {
      _readManual(value);
      return;
    }
    final lastSeparator = value.lastIndexOf(RegExp(r'[\s,]'));
    if (lastSeparator < 0) return;
    _readManual(value.substring(0, lastSeparator + 1));
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
      setState(
        () => _reconstructionMessage = 'Árbol reconstruido correctamente.',
      );
      AppToast.show(
        context,
        'BST reconstruido correctamente.',
        icon: Icons.account_tree_rounded,
      );
    } on FormatException catch (error) {
      setState(() {
        _reconstructionError = error.message;
        _reconstructionMessage = null;
      });
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
    _savedManualText = null;
    _savedQuantity = null;
    _savedFirstText = null;
    _savedSecondText = null;
    _savedMode = null;
    _savedFirstType = null;
    _savedSecondType = null;
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
      setState(() {
        _savedJson = _tree.toJson();
        _captureSavedInputs();
      });
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
      _captureSavedInputs();
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
    Widget action(
      String label,
      IconData icon,
      VoidCallback? onPressed, {
      String? disabledHint,
    }) {
      final tooltip = onPressed == null ? disabledHint ?? label : label;
      return Tooltip(
        message: tooltip,
        child: compact
            ? IconButton(onPressed: onPressed, icon: Icon(icon))
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 19),
                label: Text(label),
              ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLow,
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
            disabledHint: 'Construye o carga un árbol para habilitar Guardar.',
          ),
          action('Guía de uso', Icons.help_outline_rounded, _showGuide),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;
          if (desktop) {
            final wide = constraints.maxWidth >= 1600;
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: wide ? 340 : 300,
                    child: _sidePanel(_inputPanel()),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _board()),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: wide ? 300 : 260,
                    child: _sidePanel(_resultsPanel()),
                  ),
                ],
              ),
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
                          height: (constraints.maxHeight - 48)
                              .clamp(480.0, 620.0)
                              .toDouble(),
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
                        _panelSurface(child: _inputPanel()),
                        const SizedBox(height: 16),
                        SizedBox(height: 420, child: _board()),
                      ],
                      const SizedBox(height: 16),
                      _panelSurface(child: _resultsPanel()),
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

  Widget _sidePanel(Widget child) =>
      SingleChildScrollView(child: _panelSurface(child: child));

  Widget _panelSurface({required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _inputPanel() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeading(Icons.input_rounded, 'Construye tu BST'),
        const SizedBox(height: 6),
        Text(
          'Agrega valores paso a paso o reconstruye el árbol con dos recorridos.',
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_InputMode>(
          segments: const [
            ButtonSegment(
              value: _InputMode.manual,
              icon: Icon(Icons.edit_outlined),
              label: Text('Manual'),
            ),
            ButtonSegment(
              value: _InputMode.traversals,
              icon: Icon(Icons.account_tree_outlined),
              label: Text('Recorridos'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) => setState(() {
            _mode = selection.first;
            _reconstructionError = null;
            _reconstructionMessage = null;
          }),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 6),
        Text(
          'Cambiar de modo conserva tus entradas y el árbol actual.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (_mode == _InputMode.manual) ...[
          Text(
            'Entrada progresiva',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manual,
            minLines: 1,
            maxLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Valores',
              hintText: 'Ejemplo: 5, 3, 7, 1, 4',
              filled: true,
              fillColor: colors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
              errorText: _manualError,
              helperMaxLines: 3,
              helperText: 'Pulsa coma, espacio o Enter para insertar cada valor. También puedes pegar una lista completa.',
            ),
            onChanged: _onManualChanged,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _readManual(_manual.text),
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('Aplicar valores pendientes'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Divider(color: colors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Generación aleatoria',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad de valores',
              filled: true,
              fillColor: colors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
              errorText: _quantityError,
            ),
            onChanged: (_) {
              if (_quantityError != null) {
                setState(() => _quantityError = null);
              }
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Generar árbol'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Cada valor estará entre 1 y 99; se permiten repetidos. Si ya existe un árbol, se pedirá confirmar antes de reemplazarlo.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ] else ...[
          Text(
            'Reconstruye a partir de recorridos',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige dos órdenes distintos e introduce todos los valores de cada uno. Ambos deben describir el mismo BST.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
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
            fieldNumber: 1,
          ),
          const SizedBox(height: 16),
          _traversalInput(
            _second,
            _secondType,
            (type) => setState(() => _secondType = type),
            BstTraversal.values.where((item) => item != _firstType).toList(),
            fieldNumber: 2,
          ),
          if (_reconstructionError != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _reconstructionError!,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (_reconstructionMessage != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _reconstructionMessage!,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _reconstruct,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Reconstruir árbol'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _traversalInput(
    TextEditingController controller,
    BstTraversal selected,
    ValueChanged<BstTraversal> onChanged,
    List<BstTraversal> options, {
    required int fieldNumber,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<BstTraversal>(
        key: ValueKey(
          '${selected.name}-${options.map((item) => item.name).join()}',
        ),
        initialValue: selected,
        decoration: InputDecoration(
          labelText: fieldNumber == 1
              ? 'Primer recorrido'
              : 'Segundo recorrido',
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          for (final type in options)
            DropdownMenuItem(value: type, child: Text(type.label)),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
            setState(() {
              _reconstructionError = null;
              _reconstructionMessage = null;
            });
          }
        },
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: '${selected.label}: valores',
          hintText: fieldNumber == 1 ? '5, 3, 7' : '3, 5, 7',
          helperText: 'Separa los valores con comas o espacios.',
          helperMaxLines: 2,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (_) {
          if (_reconstructionError != null || _reconstructionMessage != null) {
            setState(() {
              _reconstructionError = null;
              _reconstructionMessage = null;
            });
          }
        },
      ),
    ],
  );

  Widget _board() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Pizarra BST',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _tree.isEmpty
                          ? 'Árbol vacío'
                          : '${_tree.distinctCount} ${_tree.distinctCount == 1 ? 'nodo único' : 'nodos únicos'} · ${_tree.totalCount} ${_tree.totalCount == 1 ? 'valor' : 'valores'}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _boardMetric('Raíz', '${_tree.root!.value}'),
                  _boardMetric('Altura', '${_tree.height}'),
                  _boardMetric(
                    'Valores repetidos',
                    '${_tree.totalCount - _tree.distinctCount}',
                  ),
                ],
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
        const SizedBox(height: 12),
        if (_tree.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Los recorridos aparecerán cuando construyas un árbol.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
              ),
            ),
          )
        else ...[
          Text(
            'Cada valor repetido aparece según su frecuencia, igual que en los nodos.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final type in BstTraversal.values) ...[
            _traversalResult(type),
            if (type != BstTraversal.postorder)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: colors.outlineVariant),
              ),
          ],
        ],
      ],
    );
  }

  Widget _traversalResult(BstTraversal type) {
    final colors = Theme.of(context).colorScheme;
    final order = switch (type) {
      BstTraversal.preorder => 'Raíz → izquierda → derecha',
      BstTraversal.inorder => 'Izquierda → raíz → derecha',
      BstTraversal.postorder => 'Izquierda → derecha → raíz',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.label,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          order,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SelectableText(
          _tree.traverse(type).join(' → '),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _boardMetric(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelHeading(IconData icon, String text) => Semantics(
    header: true,
    child: Row(
      children: [
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _BstGuideDialog extends StatelessWidget {
  const _BstGuideDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const accent = Color(0xFF7461AE);
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: size.height * .88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .16),
                  border: Border.all(color: accent.withValues(alpha: .42)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_tree_rounded, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Árboles BST',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Guía de uso · Inserción, reconstrucción y recorridos',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar guía',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _item(
                        context,
                        1,
                        Icons.edit_note_rounded,
                        'Insertar valores',
                        'Escribe valores separados por comas, espacios o Enter: cada separador incorpora el valor completo. También puedes pegar una lista. Usa “Aplicar valores pendientes” para confirmar lo que quede escrito. El primer valor será la raíz.',
                      ),
                      _item(
                        context,
                        2,
                        Icons.auto_awesome_rounded,
                        'Generar un árbol',
                        'Elige cuántos valores crear y pulsa “Generar árbol”. Los valores aleatorios están entre 1 y 99; los repetidos comparten nodo y muestran su frecuencia ×N.',
                      ),
                      _item(
                        context,
                        3,
                        Icons.account_tree_outlined,
                        'Reconstruir',
                        'Cambia a Recorridos, elige dos tipos diferentes e introduce ambas secuencias. Por ejemplo, Preorder 5, 3, 7 e Inorder 3, 5, 7.',
                      ),
                      _item(
                        context,
                        4,
                        Icons.format_list_numbered_rounded,
                        'Leer recorridos',
                        'Preorder visita primero la raíz; Inorder da las claves ordenadas; Postorder deja la raíz al final. Cada frecuencia se repite en el resultado.',
                      ),
                      _item(
                        context,
                        5,
                        Icons.folder_open_rounded,
                        'Archivos y vista',
                        'Nuevo limpia la práctica; Guardar conserva el árbol en este navegador y Cargar recupera uno guardado. Usa +, − y centrar para explorar árboles grandes.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int number,
    IconData icon,
    String title,
    String body,
  ) {
    final colors = Theme.of(context).colorScheme;
    const accent = Color(0xFF7461AE);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
