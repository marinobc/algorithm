import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nodos/application/providers/config_provider.dart';
import 'package:nodos/domain/models/modo_tipo_nodo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigProvider Node Type Mode Tests', () {
    test('Initial mode is declarado', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(configProvider);
      expect(state.modoTipoNodo, equals(ModoTipoNodo.declarado));
    });

    test('Updating modoTipoNodo updates state correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(configProvider.notifier).setModoTipoNodo(ModoTipoNodo.detectado);

      final state = container.read(configProvider);
      expect(state.modoTipoNodo, equals(ModoTipoNodo.detectado));
    });
  });
}
