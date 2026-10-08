import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nodos/application/providers/config_provider.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/modo_tipo_nodo.dart';
import 'package:nodos/algorithms/assignment/domain/policy/assignment_graph_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auto Role Detection on Connection in detectado Mode', () {
    test('Automatically assigns origen and destino roles when connecting unassigned nodes', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set mode to detectado
      container.read(configProvider.notifier).setModoTipoNodo(ModoTipoNodo.detectado);

      final policy = const AssignmentGraphPolicy();
      final n1 = policy.prepareNewNode(container.read(grafoProvider), 0, 0);
      final n2 = policy.prepareNewNode(container.read(grafoProvider), 100, 100);

      container.read(grafoProvider.notifier).agregarNodoInstancia(n1);
      container.read(grafoProvider.notifier).agregarNodoInstancia(n2);

      // Verify initially no roles assigned
      expect(container.read(grafoProvider).nodos[n1.id]?.rol, isNull);
      expect(container.read(grafoProvider).nodos[n2.id]?.rol, isNull);

      // Connect n1 -> n2
      final conns = container.read(grafoProvider.notifier).agregarConexion(n1.id, n2.id);

      // Verify roles assigned automatically upon connection
      expect(container.read(grafoProvider).nodos[n1.id]?.rol, equals('origen'));
      expect(container.read(grafoProvider).nodos[n2.id]?.rol, equals('destino'));

      // Remove connection
      container.read(grafoProvider.notifier).eliminarConexion(conns.first.id);

      // Verify roles return to unassigned (null/blank)
      expect(container.read(grafoProvider).nodos[n1.id]?.rol, isNull);
      expect(container.read(grafoProvider).nodos[n2.id]?.rol, isNull);
    });
  });
}
