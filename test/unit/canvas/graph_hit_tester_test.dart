import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/canvas/graph_hit_tester.dart';

void main() {
  const origin = Nodo(
    id: 'origin',
    nombre: 'A',
    colorValue: 0xFF7C3AED,
    x: 100,
    y: 100,
    rol: 'northwest_origin',
    cantidad: 20,
  );
  const destination = Nodo(
    id: 'destination',
    nombre: 'D1',
    colorValue: 0xFF00A884,
    x: 500,
    y: 100,
    rol: 'northwest_destination',
    cantidad: 30,
  );

  test('detecta las etiquetas editables de oferta y demanda', () {
    expect(
      GraphHitTester.hitTestQuantityLabel(const Offset(45, 100), [origin]),
      same(origin),
    );
    expect(
      GraphHitTester.hitTestQuantityLabel(const Offset(555, 100), [
        destination,
      ]),
      same(destination),
    );
  });

  test('no confunde el cuerpo del nodo con su etiqueta lateral', () {
    expect(
      GraphHitTester.hitTestQuantityLabel(const Offset(100, 100), [origin]),
      isNull,
    );
  });
}
