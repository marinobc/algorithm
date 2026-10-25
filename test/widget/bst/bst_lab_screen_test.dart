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
    expect(find.text('Árbol vacío'), findsOneWidget);
    await tester.enterText(field('Valores'), '15');
    await tester.pump();
    expect(find.text('Árbol vacío'), findsOneWidget);
    await tester.enterText(field('Valores'), '15,');
    await tester.pumpAndSettle();
    expect(find.text('1 nodo único · 1 valor'), findsOneWidget);
    expect(results(tester), ['15', '15', '15']);

    await tester.enterText(field('Valores'), '5,3,7,1,4,11,8,15,');
    await tester.pumpAndSettle();
    expect(find.text('8 nodos únicos · 8 valores'), findsOneWidget);
    expect(results(tester), [
      '5 → 3 → 1 → 4 → 7 → 11 → 8 → 15',
      '1 → 3 → 4 → 5 → 7 → 8 → 11 → 15',
      '1 → 4 → 3 → 8 → 15 → 11 → 7 → 5',
    ]);

    await tester.enterText(field('Valores'), '5,3,7,1,4');
    await tester.pumpAndSettle();
    expect(find.text('5 nodos únicos · 5 valores'), findsOneWidget);
    expect(results(tester), [
      '5 → 3 → 1 → 4 → 7',
      '1 → 3 → 4 → 5 → 7',
      '1 → 4 → 3 → 7 → 5',
    ]);

    await tester.enterText(field('Valores'), '5,3,x,');
    await tester.pumpAndSettle();
    expect(find.textContaining('no es un entero'), findsOneWidget);
    expect(results(tester), [
      '5 → 3 → 1 → 4 → 7',
      '1 → 3 → 4 → 5 → 7',
      '1 → 4 → 3 → 7 → 5',
    ]);
  });

  testWidgets('el estado vacío explica cómo empezar sin repetir resultados', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('Construye tu primer árbol BST'), findsOneWidget);
    expect(
      find.text('Los recorridos aparecerán cuando construyas un árbol.'),
      findsOneWidget,
    );
    expect(find.text('Sin valores'), findsNothing);
  });

  testWidgets('cambiar de modo conserva entradas y árbol', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(field('Valores'), '5,3,7,');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recorridos').first);
    await tester.pumpAndSettle();
    expect(find.text('3 nodos únicos · 3 valores'), findsOneWidget);
    await tester.tap(find.text('Manual').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Valores')).controller!.text,
      '5,3,7,',
    );
    expect(find.text('3 nodos únicos · 3 valores'), findsOneWidget);
  });

  testWidgets('generar árbol respeta cantidad y confirma antes de reemplazar', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.enterText(field('Valores'), '5,3,7,');
    await tester.pumpAndSettle();
    await tester.enterText(field('Cantidad de valores'), '5');
    await tester.ensureVisible(find.text('Generar árbol'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generar árbol'));
    await tester.pumpAndSettle();
    expect(find.text('Generar otro árbol'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('3 nodos únicos · 3 valores'), findsOneWidget);

    await tester.ensureVisible(find.text('Generar árbol'));
    await tester.tap(find.text('Generar árbol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· 5 valores'), findsOneWidget);
    expect(
      results(tester).every((result) => result!.split(' → ').length == 5),
      isTrue,
    );
    AppToast.dismiss();
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

    await tester.enterText(field('Inorder: valores'), '3,5,7');
    await tester.ensureVisible(find.text('Reconstruir árbol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconstruir árbol'));
    await tester.pumpAndSettle();
    expect(find.text('Árbol reconstruido correctamente.'), findsOneWidget);
    expect(results(tester), ['5 → 3 → 7', '3 → 5 → 7', '3 → 7 → 5']);
    AppToast.dismiss();
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
    expect(find.text('Árbol vacío'), findsOneWidget);

    await tester.tap(find.text('Cargar').first);
    await tester.pumpAndSettle();
    expect(find.text('Práctica BST'), findsOneWidget);
    await tester.tap(find.text('Práctica BST'));
    await tester.pumpAndSettle();
    expect(find.text('3 nodos únicos · 4 valores'), findsOneWidget);
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

  for (final viewport in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1366, 768),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'laboratorio sin desbordamientos a ${viewport.width.toInt()}×${viewport.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(app());
        await tester.enterText(
          field('Valores'),
          '${List.generate(15, (index) => index + 1).join(',')},',
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          results(tester).last,
          List.generate(15, (index) => 15 - index).join(' → '),
        );
      },
    );
  }
}
