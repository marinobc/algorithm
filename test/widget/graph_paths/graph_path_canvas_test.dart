import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/application/providers/config_provider.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/ui/screens/graph_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Dijkstra crea B→A y luego A→B aunque la preferencia global sea no dirigida',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_default_conn_type': 'ninguna',
      });
      tester.view.physicalSize = const Size(1366, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      container
          .read(activeAlgorithmProvider.notifier)
          .selectById(AlgorithmRegistry.dijkstraId);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GraphEditorScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(configProvider).tipoConexionPorDefecto,
        Direccion.ninguna,
      );
      await tester.tapAt(const Offset(220, 420));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(510, 510));
      await tester.pumpAndSettle();
      final nodes = container.read(grafoProvider).nodos.values.toList();

      await tester.dragFrom(const Offset(510, 510), const Offset(-290, -90));
      await tester.pumpAndSettle();
      expect(find.text('Peso de la arista'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '7');
      await tester.tap(find.text('Confirmar peso'));
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(220, 420), const Offset(290, 90));
      await tester.pumpAndSettle();
      expect(find.text('Peso de la arista'), findsOneWidget);
      expect(
        find.textContaining('Ya existe una arista entre estos vértices'),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Confirmar peso'));
      await tester.pumpAndSettle();

      final edges = container.read(grafoProvider).conexiones.values.toList();
      expect(edges, hasLength(2));
      expect(edges.map((edge) => edge.id).toSet(), hasLength(2));
      final reverse = edges.singleWhere(
        (edge) =>
            edge.nodoOrigenId == nodes[1].id &&
            edge.nodoDestinoId == nodes[0].id,
      );
      final forward = edges.singleWhere(
        (edge) =>
            edge.nodoOrigenId == nodes[0].id &&
            edge.nodoDestinoId == nodes[1].id,
      );
      expect(reverse.direccion, Direccion.unidireccional);
      expect(reverse.atributos.single.valor, '7');
      expect(forward.direccion, Direccion.unidireccional);
      expect(forward.atributos.single.valor, '2');

      await tester.dragFrom(const Offset(220, 420), const Offset(290, 90));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ya existe una arista entre estos vértices'),
        findsOneWidget,
      );
      expect(container.read(grafoProvider).conexiones, hasLength(2));
    await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );

  testWidgets('Dijkstra conserva A→B y B→A con pesos independientes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(220, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(510, 510));
    await tester.pumpAndSettle();
    final nodes = container.read(grafoProvider).nodos.values.toList();
    expect(nodes, hasLength(2));

    await tester.dragFrom(const Offset(220, 420), const Offset(290, 90));
    await tester.pumpAndSettle();
    expect(find.text('Peso de la arista'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '2');
    await tester.tap(find.text('Confirmar peso'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(510, 510), const Offset(-290, -90));
    await tester.pumpAndSettle();
    expect(find.text('Peso de la arista'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '7');
    await tester.tap(find.text('Confirmar peso'));
    await tester.pumpAndSettle();

    final connections = container
        .read(grafoProvider)
        .conexiones
        .values
        .toList();
    expect(connections, hasLength(2));
    expect(connections.map((edge) => edge.id).toSet(), hasLength(2));
    final forward = connections.singleWhere(
      (edge) =>
          edge.nodoOrigenId == nodes[0].id && edge.nodoDestinoId == nodes[1].id,
    );
    final reverse = connections.singleWhere(
      (edge) =>
          edge.nodoOrigenId == nodes[1].id && edge.nodoDestinoId == nodes[0].id,
    );
    expect(forward.direccion, Direccion.unidireccional);
    expect(reverse.direccion, Direccion.unidireccional);
    expect(forward.atributos.single.valor, '2');
    expect(reverse.atributos.single.valor, '7');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('Kruskal construye el grafo en el canvas compartido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.kruskalId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(220, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(510, 510));
    await tester.pumpAndSettle();
    expect(container.read(grafoProvider).nodos.length, 2);
    expect(
      container
          .read(grafoProvider)
          .nodos
          .values
          .map((node) => node.colorValue)
          .toSet()
          .length,
      2,
    );
    await tester.dragFrom(const Offset(220, 420), const Offset(290, 90));
    await tester.pumpAndSettle();
    expect(container.read(grafoProvider).conexiones.length, 1);
    expect(
      container.read(grafoProvider).conexiones.values.single.direccion,
      Direccion.ninguna,
    );
    expect(find.text('Peso de la arista'), findsOneWidget);
    final input = find.byType(TextField).last;
    await tester.enterText(input, '-3');
    await tester.tap(find.text('Confirmar peso'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(grafoProvider)
          .conexiones
          .values
          .single
          .atributos
          .where((a) => a.atributoId == 'attr_valor')
          .single
          .valor,
      '-3',
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
