import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/bst/ui/bst_lab_screen.dart';
import 'package:nodos/ui/widgets/app_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Widget app() => const MaterialApp(home: BstLabScreen());
  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  List<String?> results(WidgetTester tester) => tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((widget) => widget.data)
      .toList();

  testWidgets('confirma números completos y actualiza recorridos', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.enterText(field('Valores'), '1');
    await tester.pump();
    expect(find.text('0 nodos'), findsOneWidget);
    await tester.enterText(field('Valores'), '15');
    await tester.pump();
    expect(find.text('0 nodos'), findsOneWidget);
    await tester.enterText(field('Valores'), '15,');
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .where((text) => text?.contains('nodo') ?? false),
      contains('1 nodo'),
    );
    expect(results(tester), ['15', '15', '15']);

    await tester.enterText(field('Valores'), '5,3,7,1,4,11,8,15,');
    await tester.pumpAndSettle();
    expect(find.text('8 nodos'), findsOneWidget);
    expect(results(tester), [
      '5 → 3 → 1 → 4 → 7 → 11 → 8 → 15',
      '1 → 3 → 4 → 5 → 7 → 8 → 11 → 15',
      '1 → 4 → 3 → 8 → 15 → 11 → 7 → 5',
    ]);
  });

  testWidgets('reconstrucción fallida conserva el árbol previo', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.enterText(field('Valores'), '5,3,7,');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recorridos').first);
    await tester.pumpAndSettle();
    await tester.enterText(field('Preorder: valores'), '5,3,7');
    await tester.enterText(field('Inorder: valores'), '7,3,5');
    await tester.ensureVisible(find.text('Reconstruir árbol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconstruir árbol'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no describen el mismo BST'), findsOneWidget);
    expect(results(tester), ['5 → 3 → 7', '3 → 5 → 7', '3 → 7 → 5']);
  });

  testWidgets('guarda y carga un árbol dentro de la aplicación', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app());
    await tester.enterText(field('Valores'), '5,7,3,3,');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar').first);
    await tester.pumpAndSettle();
    await tester.enterText(field('Nombre del árbol'), 'Práctica BST');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Árbol guardado como'), findsOneWidget);

    await tester.tap(find.text('Nuevo').first);
    await tester.pumpAndSettle();
    expect(find.text('0 nodos'), findsOneWidget);

    await tester.tap(find.text('Cargar').first);
    await tester.pumpAndSettle();
    expect(find.text('Práctica BST'), findsOneWidget);
    await tester.tap(find.text('Práctica BST'));
    await tester.pumpAndSettle();
    expect(find.text('3 nodos'), findsOneWidget);
    expect(
      tester.widget<TextField>(field('Valores')).controller!.text,
      '5,7,3,3,',
    );
    expect(results(tester), [
      '5 → 3 → 3 → 7',
      '3 → 3 → 5 → 7',
      '3 → 3 → 7 → 5',
    ]);
    AppToast.dismiss();
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('laboratorio sin desbordamientos a ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(app());
      await tester.enterText(field('Valores'), '5,3,7,1,4,11,8,15,');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(results(tester).last, '1 → 4 → 3 → 8 → 15 → 11 → 7 → 5');
    });
  }
}
