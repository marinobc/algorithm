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

    test('selectBestConnectionPoint calculates exact perimeter point at target angle', () {
      const node = Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0);
      final bestRight = GraphGeometry.selectBestConnectionPoint(node, 100, 0);
      expect(bestRight.angleRadians, closeTo(0.0, 0.001));

      final bestDown = GraphGeometry.selectBestConnectionPoint(node, 0, 100);
      expect(bestDown.angleRadians, closeTo(3.14159 / 2, 0.001));

      // Continuous angle (not snapped to 30 degrees, e.g. 15 degrees)
      final targetX = 100.0 * 0.9659; // cos(15 deg)
      final targetY = 100.0 * 0.2588; // sin(15 deg)
      final bestCustom = GraphGeometry.selectBestConnectionPoint(node, targetX, targetY);
      expect(bestCustom.angleRadians, closeTo(0.26179, 0.005)); // ~15 deg in radians
    });

    test('getPerimeterPoint anchors to outer edge of wide capsule node with text', () {
      const nodeLongText = Nodo(
        id: 'n1',
        nombre: 'Nodo con un texto muy largo para probar capsula',
        colorValue: 0xFF2196F3,
        x: 0,
        y: 0,
      );

      final width = GraphGeometry.getNodeWidth(nodeLongText);
      expect(width, greaterThan(100.0));

      final edgePointRight = GraphGeometry.getPerimeterPoint(nodeLongText, 0);
      // Anchor X should be at half-width (edge of capsule), not fixed radius 32
      expect(edgePointRight.x, closeTo(width / 2.0, 0.01));
      expect(edgePointRight.y, closeTo(0.0, 0.01));
    });

    test('isValidNodePosition allows node placement anywhere within world bounds', () {
      const existing = [Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0)];

      // Overlapping or close position is valid (no jump restriction)
      expect(
        GraphGeometry.isValidNodePosition(
          candidateX: 10.0,
          candidateY: 0.0,
          candidateId: 'n2',
          existingNodes: existing,
        ),
        isTrue,
      );
    });

    test('calculateBezierCurve for self-loop produces loop curve above node', () {
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
    });

    test('getNearestValidPosition clamps within world grid bounds without pushing nodes away', () {
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

      expect(pos.x, equals(10.0));
      expect(pos.y, equals(0.0));
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
