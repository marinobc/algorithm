import 'dart:convert';

enum BstTraversal { preorder, inorder, postorder }

extension BstTraversalLabel on BstTraversal {
  String get label => switch (this) {
    BstTraversal.preorder => 'Preorder',
    BstTraversal.inorder => 'Inorder',
    BstTraversal.postorder => 'Postorder',
  };
}

class BstNode {
  final String id;
  final int value;
  final int frequency;
  final BstNode? left;
  final BstNode? right;

  const BstNode({
    required this.id,
    required this.value,
    this.frequency = 1,
    this.left,
    this.right,
  });
}

class BstTree {
  final BstNode? root;
  final int _nextId;

  const BstTree._(this.root, this._nextId);

  const BstTree.empty() : root = null, _nextId = 1;

  bool get isEmpty => root == null;

  int get distinctCount => _count(root);
  int get totalCount => _total(root);
  int get height => _height(root);

  static int _count(BstNode? node) =>
      node == null ? 0 : 1 + _count(node.left) + _count(node.right);
  static int _total(BstNode? node) => node == null
      ? 0
      : node.frequency + _total(node.left) + _total(node.right);
  static int _height(BstNode? node) => node == null
      ? 0
      : 1 +
            (_height(node.left) > _height(node.right)
                ? _height(node.left)
                : _height(node.right));

  BstTree insert(int value) {
    BstNode add(BstNode? node) {
      if (node == null) return BstNode(id: 'n$_nextId', value: value);
      if (value < node.value) {
        return BstNode(
          id: node.id,
          value: node.value,
          frequency: node.frequency,
          left: add(node.left),
          right: node.right,
        );
      }
      if (value > node.value) {
        return BstNode(
          id: node.id,
          value: node.value,
          frequency: node.frequency,
          left: node.left,
          right: add(node.right),
        );
      }
      return BstNode(
        id: node.id,
        value: node.value,
        frequency: node.frequency + 1,
        left: node.left,
        right: node.right,
      );
    }

    final exists = find(value) != null;
    return BstTree._(add(root), exists ? _nextId : _nextId + 1);
  }

  BstNode? find(int value) {
    var current = root;
    while (current != null) {
      if (value == current.value) return current;
      current = value < current.value ? current.left : current.right;
    }
    return null;
  }

  List<int> insertionPath(int value) {
    final path = <int>[];
    var current = root;
    while (current != null) {
      path.add(current.value);
      if (value == current.value) break;
      current = value < current.value ? current.left : current.right;
    }
    return path;
  }

  List<int> traverse(BstTraversal order) {
    final values = <int>[];
    void visit(BstNode? node) {
      if (node == null) return;
      void append() {
        for (var i = 0; i < node.frequency; i++) {
          values.add(node.value);
        }
      }

      if (order == BstTraversal.preorder) append();
      visit(node.left);
      if (order == BstTraversal.inorder) append();
      visit(node.right);
      if (order == BstTraversal.postorder) append();
    }

    visit(root);
    return values;
  }

  static BstTree fromValues(Iterable<int> values) {
    var tree = const BstTree.empty();
    for (final value in values) {
      tree = tree.insert(value);
    }
    return tree;
  }

  static List<int> parseValues(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];
    final tokens = trimmed
        .split(RegExp(r'[\s,]+'))
        .where((token) => token.isNotEmpty);
    final values = <int>[];
    for (final token in tokens) {
      final value = int.tryParse(token);
      if (value == null) {
        throw FormatException(
          '"$token" no es un entero. Usa comas o espacios para separar valores.',
        );
      }
      values.add(value);
    }
    return values;
  }

  static BstTree reconstruct({
    required BstTraversal firstType,
    required List<int> first,
    required BstTraversal secondType,
    required List<int> second,
  }) {
    if (firstType == secondType) {
      throw const FormatException('Escoge dos recorridos diferentes.');
    }
    if (first.length != second.length) {
      throw const FormatException(
        'Los recorridos deben tener la misma cantidad de valores.',
      );
    }
    final frequencies = <int, int>{};
    for (final value in first) {
      frequencies.update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final value in second) {
      final remaining = frequencies[value];
      if (remaining == null || remaining == 0) {
        throw const FormatException(
          'Los recorridos deben contener los mismos valores y frecuencias.',
        );
      }
      frequencies[value] = remaining - 1;
    }
    if (frequencies.values.any((remaining) => remaining != 0)) {
      throw const FormatException(
        'Los recorridos deben contener los mismos valores y frecuencias.',
      );
    }

    // A node is visited once; its frequency must form one contiguous run.
    for (final sequence in [first, second]) {
      final completed = <int>{};
      int? previous;
      for (final value in sequence) {
        if (value != previous) {
          if (completed.contains(value)) {
            throw const FormatException(
              'Cada valor repetido debe aparecer junto en ambos recorridos.',
            );
          }
          if (previous != null) completed.add(previous);
          previous = value;
        }
      }
    }

    final source = firstType == BstTraversal.preorder
        ? first
        : secondType == BstTraversal.preorder
        ? second
        : firstType == BstTraversal.postorder
        ? first.reversed
        : second.reversed;
    final candidate = BstTree.fromValues(source);
    if (!_same(candidate.traverse(firstType), first) ||
        !_same(candidate.traverse(secondType), second)) {
      throw const FormatException(
        'Los recorridos no describen el mismo BST. Revisa el orden de las claves.',
      );
    }
    return candidate;
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String toJson() {
    final nodes = <Map<String, Object?>>[];
    void collect(BstNode? node) {
      if (node == null) return;
      nodes.add({
        'id': node.id,
        'value': node.value,
        'frequency': node.frequency,
        'left': node.left?.id,
        'right': node.right?.id,
      });
      collect(node.left);
      collect(node.right);
    }

    collect(root);
    return const JsonEncoder.withIndent('  ')
        .convert({'version': 1, 'root': root?.id, 'nodes': nodes});
  }

  static BstTree fromJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('El archivo no contiene JSON válido.');
    }
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException(
        'El archivo no tiene un formato BST compatible (versión 1).',
      );
    }
    final rawNodes = decoded['nodes'];
    final rootId = decoded['root'];
    if (rawNodes is! List || (rootId != null && rootId is! String)) {
      throw const FormatException(
        'La raíz o la lista de nodos tiene un formato inválido.',
      );
    }
    final records = <String, Map<String, dynamic>>{};
    for (final raw in rawNodes) {
      if (raw is! Map<String, dynamic> ||
          raw['id'] is! String ||
          (raw['id'] as String).isEmpty ||
          raw['value'] is! int ||
          raw['frequency'] is! int ||
          (raw['frequency'] as int) < 1 ||
          (raw['left'] != null && raw['left'] is! String) ||
          (raw['right'] != null && raw['right'] is! String)) {
        throw const FormatException(
          'Un nodo tiene identificador, valor, frecuencia o enlaces inválidos.',
        );
      }
      final id = raw['id'] as String;
      if (records.containsKey(id)) {
        throw const FormatException('Hay identificadores de nodo repetidos.');
      }
      records[id] = raw;
    }
    if (records.isEmpty && rootId == null) return const BstTree.empty();
    if (rootId == null || !records.containsKey(rootId)) {
      throw const FormatException('La raíz no existe en la lista de nodos.');
    }
    final visited = <String>{};
    BstNode build(String id, int? lower, int? upper) {
      final record = records[id];
      if (record == null) {
        throw const FormatException('Un hijo apunta a un nodo inexistente.');
      }
      if (!visited.add(id)) {
        throw const FormatException(
          'El archivo contiene un ciclo o un nodo con varios padres.',
        );
      }
      final value = record['value'] as int;
      if ((lower != null && value <= lower) ||
          (upper != null && value >= upper)) {
        throw const FormatException(
          'Un nodo está fuera del rango permitido por la propiedad BST.',
        );
      }
      final leftId = record['left'] as String?;
      final rightId = record['right'] as String?;
      return BstNode(
        id: id,
        value: value,
        frequency: record['frequency'] as int,
        left: leftId == null ? null : build(leftId, lower, value),
        right: rightId == null ? null : build(rightId, value, upper),
      );
    }

    final root = build(rootId, null, null);
    if (visited.length != records.length) {
      throw const FormatException(
        'El archivo contiene nodos desconectados de la raíz.',
      );
    }
    var nextId = 1;
    for (final id in records.keys) {
      final number = id.startsWith('n') ? int.tryParse(id.substring(1)) : null;
      if (number != null && number >= nextId) nextId = number + 1;
    }
    return BstTree._(root, nextId);
  }
}
