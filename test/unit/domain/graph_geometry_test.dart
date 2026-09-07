import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/graph_geometry.dart';

void main() {
  group('Domain - GraphGeometry', () {
    test('get12ConnectionPoints produces 12 points at 30 degree intervals', () {
      const node = Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 100, y: 100);

      final points = GraphGeometry.get12ConnectionPoints(node);
      expect(points.length, equals(12));

      // Index 0: 0 rad -> (100 + radius, 100)
      expect(points[0].point.x, closeTo(100.0 + node.radius, 0.001));
      expect(points[0].point.y, closeTo(100.0, 0.001));

      // Index 3: 90 deg (pi/2) -> (100, 100 + radius)
      expect(points[3].point.x, closeTo(100.0, 0.001));
      expect(points[3].point.y, closeTo(100.0 + node.radius, 0.001));
    });

    test('selectBestConnectionPoint chooses point facing target', () {
      const node = Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0);
      final bestRight = GraphGeometry.selectBestConnectionPoint(node, 100, 0);
      expect(bestRight.index, equals(0));

      final bestDown = GraphGeometry.selectBestConnectionPoint(node, 0, 100);
      expect(bestDown.index, equals(3));
    });

    test(
      'isValidNodePosition enforces minimum distance of 1 node diameter',
      () {
        const existing = [Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0)];

        // Center-to-center distance < 100.0 (2 * diameter requirement)
        expect(
          GraphGeometry.isValidNodePosition(
            candidateX: 50.0,
            candidateY: 0.0,
            candidateId: 'n2',
            existingNodes: existing,
          ),
          isFalse,
        );

        // Distance >= 100.0
        expect(
          GraphGeometry.isValidNodePosition(
            candidateX: 100.0,
            candidateY: 0.0,
            candidateId: 'n2',
            existingNodes: existing,
          ),
          isTrue,
        );
      },
    );

    test(
      'calculateBezierCurve for self-loop produces loop curve above node',
      () {
        const node = Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0);
        final curve = GraphGeometry.calculateBezierCurve(
          origen: node,
          destino: node,
        );

        expect(curve.start, isNotNull);
        expect(curve.end, isNotNull);
        // Control points loop above node (negative Y)
        expect(curve.control1.y, lessThan(0));
        expect(curve.control2.y, lessThan(0));
      },
    );

    test('getNearestValidPosition uses multi-pass solver to prevent cascading collisions', () {
      const existing = [
        Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0),
        Nodo(id: 'n2', colorValue: 0xFF2196F3, x: 100, y: 0),
      ];

      final pos = GraphGeometry.getNearestValidPosition(
        candidateX: 10,
        candidateY: 0,
        candidateId: 'n3',
        existingNodes: existing,
      );

      // Multi-pass solver ensures pos does not collide with n1 OR n2
      expect(
        GraphGeometry.isValidNodePosition(
          candidateX: pos.x,
          candidateY: pos.y,
          candidateId: 'n3',
          existingNodes: existing,
        ),
        isTrue,
      );
    });

    test('2D offsetControlX and offsetControlY curve control points', () {
      const nodeA = Nodo(id: 'a', colorValue: 0xFF000000, x: 0, y: 0);
      const nodeB = Nodo(id: 'b', colorValue: 0xFF000000, x: 200, y: 0);

      final curve = GraphGeometry.calculateBezierCurve(
        origen: nodeA,
        destino: nodeB,
        offsetControlX: 50.0,
        offsetControlY: 100.0,
      );

      expect(curve.start, isNotNull);
      expect(curve.end, isNotNull);
      // Control point Y shifted by 100.0
      expect(curve.control1.y, greaterThan(50.0));
      expect(curve.control2.y, greaterThan(50.0));
    });
  });
}
