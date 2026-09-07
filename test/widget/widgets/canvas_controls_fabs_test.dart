import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/ui/theme/app_theme.dart';
import 'package:nodos/ui/widgets/canvas_controls_fabs.dart';

void main() {
  group('Widget - CanvasControlsFabs Tests', () {
    testWidgets('renders center FAB and responds to click', (tester) async {
      bool centerClicked = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: CanvasControlsFabs(
                onResetView: () {
                  centerClicked = true;
                },
              ),
            ),
          ),
        ),
      );

      final centerBtn = find.byIcon(Icons.center_focus_strong_rounded);
      expect(centerBtn, findsOneWidget);

      await tester.tap(centerBtn);
      await tester.pump();

      expect(centerClicked, isTrue);
    });

    test('cargarGrafo updates riverpod state and records undo state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(grafoProvider.notifier);
      expect(notifier.state.nodos, isEmpty);

      const n1 = Nodo(id: 'n1', colorValue: 0, x: 10, y: 20);
      final newGraph = Grafo(nodos: {'n1': n1});

      notifier.cargarGrafo(newGraph);
      expect(notifier.state.nodos.length, equals(1));
      expect(notifier.state.nodos['n1']?.x, equals(10));
      expect(notifier.puedeDeshacer, isFalse);
    });
  });
}
