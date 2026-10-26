import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/application/providers/edicion_provider.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/widgets/edit_panel.dart';

void main() {
  for (final (id, value) in [
    (AlgorithmRegistry.dijkstraId, '0'),
    (AlgorithmRegistry.kruskalId, '-2.5'),
  ]) {
    testWidgets('panel compartido guarda peso $value en $id', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      container
          .read(grafoProvider.notifier)
          .cargarGrafo(
            Grafo(
              nodos: {
                for (final nodeId in ['A', 'B'])
                  nodeId: Nodo(
                    id: nodeId,
                    nombre: nodeId,
                    colorValue: 0xFF7461AE,
                    x: 0,
                    y: 0,
                  ),
              },
              conexiones: {
                'AB': const Conexion(
                  id: 'AB',
                  nodoOrigenId: 'A',
                  nodoDestinoId: 'B',
                  colorValue: 0xFF7461AE,
                  atributos: [
                    AtributoValor(atributoId: 'attr_valor', valor: '1'),
                  ],
                ),
              },
            ),
          );
      container.read(activeAlgorithmProvider.notifier).selectById(id);
      container.read(estadoEdicionProvider.notifier).seleccionarConexion('AB');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: EditPanel())),
        ),
      );
      await tester.pumpAndSettle();
      final valueField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Valor',
      );
      expect(valueField, findsOneWidget);
      await tester.enterText(valueField, value);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final stored = container
          .read(grafoProvider)
          .conexiones['AB']!
          .atributos
          .where((attr) => attr.atributoId == 'attr_valor')
          .single
          .valor;
      expect(stored, value);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  }

  testWidgets('Kruskal exige corregir la dirección antes de guardar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          Grafo(
            nodos: {
              for (final id in ['A', 'B'])
                id: Nodo(
                  id: id,
                  nombre: id,
                  colorValue: 0xFF7461AE,
                  x: 0,
                  y: 0,
                ),
            },
            conexiones: {
              'AB': const Conexion(
                id: 'AB',
                nodoOrigenId: 'A',
                nodoDestinoId: 'B',
                colorValue: 0xFF7461AE,
                direccion: Direccion.unidireccional,
                atributos: [
                  AtributoValor(atributoId: 'attr_valor', valor: '1'),
                ],
              ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.kruskalId);
    container.read(estadoEdicionProvider.notifier).seleccionarConexion('AB');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: EditPanel())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      container.read(grafoProvider).conexiones['AB']!.direccion,
      Direccion.unidireccional,
    );
    await tester.tap(find.text('No dirigida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      container.read(grafoProvider).conexiones['AB']!.direccion,
      Direccion.ninguna,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
