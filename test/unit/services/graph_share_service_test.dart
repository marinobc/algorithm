import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/graph_image_exporter.dart';
import 'package:nodos/domain/services/graph_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphShareService & GraphImageExporter Unit Tests', () {
    test('generateThumbnailBase64 returns null for empty graph', () async {
      const emptyGraph = Grafo();
      final result = await GraphShareService.generateThumbnailBase64(emptyGraph);
      expect(result, isNull);
    });

    test('generateThumbnailBase64 generates base64 string for graph with nodes',
        () async {
      const nodeA = Nodo(id: 'n1', x: 100, y: 100, colorValue: 0xFF2196F3, nombre: 'Nodo A');
      const sampleGraph = Grafo(nodos: {'n1': nodeA});

      final base64Result =
          await GraphImageExporter.generateThumbnailBase64(sampleGraph);
      expect(base64Result, isNotNull);
      expect(base64Result!.length, greaterThan(0));
    });

    test('generateGraphJpgBytes produces non-empty bytes array', () async {
      const nodeA = Nodo(id: 'n1', x: 100, y: 100, colorValue: 0xFF2196F3, nombre: 'Nodo A');
      const sampleGraph = Grafo(nodos: {'n1': nodeA});

      final bytes = await GraphShareService.generateGraphJpgBytes(
        sampleGraph,
        graphName: 'Grafo de Prueba',
      );
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(0));
    });

    test('generateUniqueExportFileName generates valid extension filename', () {
      final fileName =
          GraphShareService.generateUniqueExportFileName('png');
      expect(fileName.endsWith('.png'), isTrue);
      expect(fileName.length, greaterThan(4));
    });
  });
}
