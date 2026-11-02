import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/canvas/graph_hit_tester.dart';
import 'package:nodos/ui/canvas/graph_render_model.dart';
import 'package:nodos/ui/theme/app_theme.dart';

void main() {
  const a = Nodo(id: 'A', nombre: 'A', colorValue: 0xFF6754B2, x: 0, y: 0);
  const b = Nodo(id: 'B', nombre: 'B', colorValue: 0xFF008F87, x: 200, y: 0);
  const ab = Conexion(
    id: 'AB',
    nodoOrigenId: 'A',
    nodoDestinoId: 'B',
    colorValue: 0xFF6754B2,
    direccion: Direccion.unidireccional,
    atributos: [AtributoValor(atributoId: 'attr_valor', valor: '2')],
  );
  const ba = Conexion(
    id: 'BA',
    nodoOrigenId: 'B',
    nodoDestinoId: 'A',
    colorValue: 0xFF008F87,
    direccion: Direccion.unidireccional,
    atributos: [AtributoValor(atributoId: 'attr_valor', valor: '7')],
  );

  final graph = Grafo(
    nodos: const {'A': a, 'B': b},
    conexiones: const {'AB': ab, 'BA': ba},
  );

  test('opposite curves, arrows, labels and hit areas remain independent', () {
    final model = GraphRenderModel.fromGrafo(
      graph,
      palette: M3Palette.light,
      distinguishOppositeDirected: true,
      selectedItemId: 'AB',
      isSelectedNode: false,
    );
    final forward = model.connections.singleWhere(
      (edge) => edge.conexionId == 'AB',
    );
    final reverse = model.connections.singleWhere(
      (edge) => edge.conexionId == 'BA',
    );
    expect(forward.isSelected, isTrue);
    expect(reverse.isSelected, isFalse);
    expect(forward.labelText, '2');
    expect(reverse.labelText, '7');
    expect(forward.labelPosition!.dy * reverse.labelPosition!.dy, lessThan(0));
    expect(
      (forward.labelPosition! - reverse.labelPosition!).distance,
      greaterThan(35),
    );
    expect(
      GraphHitTester.distanceToNodeBoundary(forward.arrowPoint!, b).abs(),
      lessThan(1),
    );
    expect(
      GraphHitTester.distanceToNodeBoundary(reverse.arrowPoint!, a).abs(),
      lessThan(1),
    );
    expect(
      GraphHitTester.hitTestConnection(
        forward.labelPosition!,
        graph,
        0.7,
        distinguishOppositeDirected: true,
      )?.id,
      'AB',
    );
    expect(
      GraphHitTester.hitTestConnection(
        reverse.labelPosition!,
        graph,
        0.7,
        distinguishOppositeDirected: true,
      )?.id,
      'BA',
    );

    final moved = graph.copyWith(
      nodos: {'A': a, 'B': b.copyWith(x: 230, y: 90)},
    );
    final movedModel = GraphRenderModel.fromGrafo(
      moved,
      palette: M3Palette.light,
      distinguishOppositeDirected: true,
    );
    for (final edge in movedModel.connections) {
      expect(
        GraphHitTester.hitTestConnection(
          edge.labelPosition!,
          moved,
          1.8,
          distinguishOppositeDirected: true,
        )?.id,
        edge.conexionId,
      );
    }

    final single = graph.copyWith(conexiones: const {'AB': ab});
    final singleModel = GraphRenderModel.fromGrafo(
      single,
      palette: M3Palette.light,
      distinguishOppositeDirected: true,
    );
    expect(
      singleModel.connections.single.labelPosition!.dy.abs(),
      lessThan(0.1),
    );
    expect(
      GraphHitTester.hitTestConnection(
        singleModel.connections.single.labelPosition!,
        single,
        1,
        distinguishOppositeDirected: true,
      )?.id,
      'AB',
    );
  });
}
