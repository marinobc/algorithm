import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/assignment_algorithm.dart';
import 'package:nodos/algorithms/assignment/ui/assignment_bipartite_matrix_screen.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/algorithms/johnson/johnson_algorithm.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/dialogs/adjacency_matrix_dialog.dart';
import 'package:nodos/ui/dialogs/matrix_view_coordinator.dart';
import 'package:nodos/ui/theme/app_theme.dart';
import 'package:nodos/ui/widgets/canvas_controls_fabs.dart';

class _TestGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _TestGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}

void main() {
  group('Modular Matrix Architecture Tests', () {
    test('Algorithm matrix support contracts are configured correctly', () {
      const assignment = AssignmentAlgorithm();
      const johnson = JohnsonAlgorithm();

      expect(assignment.supportsMatrix, isTrue);
      expect(assignment.matrixUnavailableReason, isNull);

      expect(johnson.supportsMatrix, isFalse);
      expect(johnson.matrixUnavailableReason, isNotNull);
      expect(johnson.matrixUnavailableReason, contains('Johnson'));
    });

    testWidgets('Coordinator opens AdjacencyMatrixScreen in Free Mode', (
      tester,
    ) async {
      final validGraph = Grafo(
        nodos: {
          'n1': const Nodo(
            id: 'n1',
            x: 0,
            y: 0,
            nombre: 'A',
            colorValue: 0xFF2196F3,
          ),
          'n2': const Nodo(
            id: 'n2',
            x: 100,
            y: 0,
            nombre: 'B',
            colorValue: 0xFF4CAF50,
          ),
        },
        conexiones: {
          'c1': const Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            direccion: Direccion.unidireccional,
            colorValue: 0xFF000000,
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          grafoProvider.overrideWith(() => _TestGrafoNotifier(validGraph)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () =>
                      MatrixViewCoordinator.openMatrix(context, ref),
                  child: const Text('Open Matrix'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Matrix'));
      await tester.pumpAndSettle();

      expect(find.byType(AdjacencyMatrixScreen), findsOneWidget);
    });

    testWidgets(
      'Coordinator opens AssignmentBipartiteMatrixScreen in Assignment Mode',
      (tester) async {
        final assignmentGraph = Grafo(
          nodos: {
            'o1': const Nodo(
              id: 'o1',
              x: 0,
              y: 0,
              nombre: 'Origen 1',
              rol: 'origen',
              colorValue: 0xFF2196F3,
            ),
            'o2': const Nodo(
              id: 'o2',
              x: 0,
              y: 50,
              nombre: 'Origen 2',
              rol: 'origen',
              colorValue: 0xFF2196F3,
            ),
            'd1': const Nodo(
              id: 'd1',
              x: 100,
              y: 0,
              nombre: 'Destino 1',
              rol: 'destino',
              colorValue: 0xFF4CAF50,
            ),
            'd2': const Nodo(
              id: 'd2',
              x: 100,
              y: 50,
              nombre: 'Destino 2',
              rol: 'destino',
              colorValue: 0xFF4CAF50,
            ),
          },
          conexiones: {
            'c1': const Conexion(
              id: 'c1',
              nodoOrigenId: 'o1',
              nodoDestinoId: 'd1',
              direccion: Direccion.unidireccional,
              colorValue: 0xFF000000,
              atributos: [AtributoValor(atributoId: 'attr_valor', valor: '15')],
            ),
            'c2': const Conexion(
              id: 'c2',
              nodoOrigenId: 'o2',
              nodoDestinoId: 'd2',
              direccion: Direccion.unidireccional,
              colorValue: 0xFF000000,
              atributos: [AtributoValor(atributoId: 'attr_valor', valor: '20')],
            ),
          },
        );

        final container = ProviderContainer(
          overrides: [
            grafoProvider.overrideWith(
              () => _TestGrafoNotifier(assignmentGraph),
            ),
          ],
        );

        // Select Assignment Algorithm
        container
            .read(activeAlgorithmProvider.notifier)
            .selectAlgorithm(const AssignmentAlgorithm());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () =>
                        MatrixViewCoordinator.openMatrix(context, ref),
                    child: const Text('Open Matrix'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Matrix'));
        await tester.pumpAndSettle();

        expect(find.byType(AssignmentBipartiteMatrixScreen), findsOneWidget);
        expect(find.text('Matriz de Costos de Asignación'), findsOneWidget);
        expect(find.text('Origen 1'), findsOneWidget);
        expect(find.text('Destino 1'), findsOneWidget);
        expect(find.text('15'), findsWidgets);
        expect(find.text('Suma Fila'), findsOneWidget);
        expect(find.text('Grado Fila'), findsOneWidget);
        expect(find.text('Suma Col.'), findsOneWidget);
        expect(find.text('Grado Col.'), findsOneWidget);
      },
    );

    testWidgets(
      'Coordinator displays informative toast in Johnson Mode without opening a matrix',
      (tester) async {
        final container = ProviderContainer();
        container
            .read(activeAlgorithmProvider.notifier)
            .selectAlgorithm(const JohnsonAlgorithm());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () =>
                          MatrixViewCoordinator.openMatrix(context, ref),
                      child: const Text('Open Matrix'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Matrix'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));

        // No matrix screens should be pushed
        expect(find.byType(AdjacencyMatrixScreen), findsNothing);
        expect(find.byType(AssignmentBipartiteMatrixScreen), findsNothing);
      },
    );

    testWidgets(
      'Matrix FAB is disabled in Free Mode when graph has disconnected nodes',
      (tester) async {
        final invalidGraph = Grafo(
          nodos: {
            'n1': const Nodo(
              id: 'n1',
              x: 0,
              y: 0,
              nombre: 'A',
              colorValue: 0xFF2196F3,
            ),
            'n2': const Nodo(
              id: 'n2',
              x: 100,
              y: 0,
              nombre: 'B',
              colorValue: 0xFF4CAF50,
            ),
          },
          conexiones: const {},
        );

        final container = ProviderContainer(
          overrides: [
            grafoProvider.overrideWith(() => _TestGrafoNotifier(invalidGraph)),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(body: const CanvasControlsFabs()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Alternative: find by tooltip or FloatingActionButton
        final fab = tester.widget<FloatingActionButton>(
          find.widgetWithText(FloatingActionButton, 'Matriz'),
        );
        expect(fab.onPressed, isNull);
      },
    );

    testWidgets(
      'Matrix FAB is disabled in Assignment Mode when bipartite graph is invalid',
      (tester) async {
        // Single node graph - invalid for bipartite assignment
        final invalidAssignmentGraph = Grafo(
          nodos: {
            'n1': const Nodo(
              id: 'n1',
              x: 0,
              y: 0,
              nombre: 'A',
              colorValue: 0xFF2196F3,
            ),
          },
          conexiones: const {},
        );

        final container = ProviderContainer(
          overrides: [
            grafoProvider.overrideWith(
              () => _TestGrafoNotifier(invalidAssignmentGraph),
            ),
          ],
        );

        container
            .read(activeAlgorithmProvider.notifier)
            .selectAlgorithm(const AssignmentAlgorithm());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(body: const CanvasControlsFabs()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.ancestor(
            of: find.byTooltip(
              'Agrega un origen y un destino para ver la matriz',
            ),
            matching: find.byType(FloatingActionButton),
          ),
        );
        expect(fab.onPressed, isNull);
      },
    );
  });
}
