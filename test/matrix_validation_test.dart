import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/grafo_invalido_provider.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/dialogs/adjacency_matrix_dialog.dart';
import 'package:nodos/ui/theme/app_theme.dart';

void main() {
  group('Matrix Validation & Screen Block Tests', () {
    testWidgets(
      'shows "Conecta el grafo para poder ver la matriz" when graph has disconnected nodes',
      (tester) async {
        // Disconnected graph with 2 nodes and 0 connections
        final invalidGraph = Grafo(
          nodos: {
            'n1': const Nodo(
              id: 'n1',
              x: 0,
              y: 0,
              nombre: 'Nodo 1',
              colorValue: 0xFF2196F3,
            ),
            'n2': const Nodo(
              id: 'n2',
              x: 100,
              y: 0,
              nombre: 'Nodo 2',
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

        expect(container.read(esGrafoInvalidoProvider), isTrue);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const AdjacencyMatrixScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the warning title message is displayed
        expect(
          find.text('Conecta el grafo para poder ver la matriz'),
          findsOneWidget,
        );
        expect(
          find.text('Existen nodos o secciones sin conectar en el lienzo.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
      },
    );

    testWidgets('renders matrix grid when graph is connected and valid', (
      tester,
    ) async {
      final validGraph = Grafo(
        nodos: {
          'n1': const Nodo(
            id: 'n1',
            x: 0,
            y: 0,
            nombre: 'Nodo 1',
            colorValue: 0xFF2196F3,
          ),
          'n2': const Nodo(
            id: 'n2',
            x: 100,
            y: 0,
            nombre: 'Nodo 2',
            colorValue: 0xFF4CAF50,
          ),
        },
        conexiones: {
          'c1': const Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            direccion: Direccion.unidireccional,
            colorValue: 0xFF2196F3,
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          grafoProvider.overrideWith(() => _TestGrafoNotifier(validGraph)),
        ],
      );

      expect(container.read(esGrafoInvalidoProvider), isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AdjacencyMatrixScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify matrix title and headers are rendered instead of the block message
      expect(find.text('Matriz de Adyacencia Ponderada'), findsOneWidget);
      expect(
        find.text('Conecta el grafo para poder ver la matriz'),
        findsNothing,
      );

      // Verify new summary headers and stats card are present
      expect(find.text('Suma Fila'), findsOneWidget);
      expect(find.text('Grado Fila'), findsOneWidget);
      expect(find.text('Suma Col.'), findsOneWidget);
      expect(find.text('Grado Col.'), findsOneWidget);
      expect(find.textContaining('Δ(G)'), findsOneWidget);
    });
  });
}

class _TestGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _TestGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}
