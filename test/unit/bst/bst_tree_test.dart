import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/bst/domain/bst_tree.dart';

void main() {
  final example = [5, 3, 7, 1, 4, 11, 8, 15];
  final preorder = [5, 3, 1, 4, 7, 11, 8, 15];
  final inorder = [1, 3, 4, 5, 7, 8, 11, 15];
  final postorder = [1, 4, 3, 8, 15, 11, 7, 5];

  test('inserción progresiva y tres recorridos del ejemplo', () {
    var tree = const BstTree.empty();
    expect(tree.traverse(BstTraversal.inorder), isEmpty);
    for (final value in example) {
      tree = tree.insert(value);
    }
    expect(tree.root?.value, 5);
    expect(tree.traverse(BstTraversal.preorder), preorder);
    expect(tree.traverse(BstTraversal.inorder), inorder);
    expect(tree.traverse(BstTraversal.postorder), postorder);
    expect(tree.distinctCount, 8);
  });

  test('duplicados y negativos usan frecuencias sin cambiar la regla BST', () {
    final tree = BstTree.fromValues([2, 3, 4, 3, 1, 2, -5]);
    expect(tree.find(2)?.frequency, 2);
    expect(tree.find(3)?.frequency, 2);
    expect(tree.traverse(BstTraversal.inorder), [-5, 1, 2, 2, 3, 3, 4]);
    expect(tree.distinctCount, 5);
    expect(tree.totalCount, 7);
  });

  test('reconstruye con cada combinación de tipos', () {
    final pairs = [
      (BstTraversal.preorder, preorder, BstTraversal.inorder, inorder),
      (BstTraversal.postorder, postorder, BstTraversal.inorder, inorder),
      (BstTraversal.preorder, preorder, BstTraversal.postorder, postorder),
    ];
    for (final (a, first, b, second) in pairs) {
      final tree = BstTree.reconstruct(
        firstType: a,
        first: first,
        secondType: b,
        second: second,
      );
      expect(tree.traverse(BstTraversal.preorder), preorder);
      expect(tree.traverse(BstTraversal.inorder), inorder);
      expect(tree.traverse(BstTraversal.postorder), postorder);
    }
  });

  test('rechaza recorridos incompatibles aunque compartan los valores', () {
    expect(
      () => BstTree.reconstruct(
        firstType: BstTraversal.preorder,
        first: [5, 3, 7],
        secondType: BstTraversal.postorder,
        second: [7, 3, 5],
      ),
      throwsFormatException,
    );
  });

  test('reconstruye frecuencias y rechaza duplicados separados', () {
    final original = BstTree.fromValues([2, 3, 4, 3, 1, 2]);
    final pre = original.traverse(BstTraversal.preorder);
    final post = original.traverse(BstTraversal.postorder);
    final loaded = BstTree.reconstruct(
      firstType: BstTraversal.preorder,
      first: pre,
      secondType: BstTraversal.postorder,
      second: post,
    );
    expect(loaded.find(2)?.frequency, 2);
    expect(loaded.find(3)?.frequency, 2);
    expect(loaded.traverse(BstTraversal.inorder), [1, 2, 2, 3, 3, 4]);
    expect(
      () => BstTree.reconstruct(
        firstType: BstTraversal.preorder,
        first: [2, 3, 2],
        secondType: BstTraversal.inorder,
        second: [2, 2, 3],
      ),
      throwsFormatException,
    );
  });

  test('JSON preserva estructura, ids y frecuencias', () {
    final original = BstTree.fromValues([5, 3, 7, 3, 8]);
    final loaded = BstTree.fromJson(original.toJson());
    expect(loaded.toJson(), original.toJson());
    expect(loaded.traverse(BstTraversal.inorder), [3, 3, 5, 7, 8]);
    expect(loaded.insert(9).find(9)?.id, isNot(loaded.root?.id));
  });

  test('JSON inválido no pasa validación estructural', () {
    final original = jsonDecode(
      BstTree.fromValues([5, 3, 7]).toJson(),
    ) as Map<String, dynamic>;
    expect(() => BstTree.fromJson('{'), throwsFormatException);
    Map<String, dynamic> copy() =>
        jsonDecode(jsonEncode(original)) as Map<String, dynamic>;

    final cycle = copy();
    (cycle['nodes'] as List)[1]['left'] = 'n1';
    expect(() => BstTree.fromJson(jsonEncode(cycle)), throwsFormatException);

    final invalidRange = copy();
    (invalidRange['nodes'] as List)[1]['value'] = 9;
    expect(
      () => BstTree.fromJson(jsonEncode(invalidRange)),
      throwsFormatException,
    );

    final frequency = copy();
    (frequency['nodes'] as List)[0]['frequency'] = 0;
    expect(
      () => BstTree.fromJson(jsonEncode(frequency)),
      throwsFormatException,
    );

    final missingChild = copy();
    (missingChild['nodes'] as List)[0]['left'] = 'missing';
    expect(
      () => BstTree.fromJson(jsonEncode(missingChild)),
      throwsFormatException,
    );
  });

  test('lista vacía, un nodo y árbol desbalanceado', () {
    expect(BstTree.parseValues('  '), isEmpty);
    expect(BstTree.parseValues('5, -3  7\n1'), [5, -3, 7, 1]);
    expect(BstTree.parseValues('15,'), [15]);
    expect(() => BstTree.parseValues('5, xx'), throwsFormatException);
    expect(BstTree.fromValues([4]).height, 1);
    expect(BstTree.fromValues([1, 2, 3, 4]).height, 4);
  });
}
