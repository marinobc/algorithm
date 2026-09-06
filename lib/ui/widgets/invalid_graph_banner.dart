import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../theme/app_theme.dart';

class InvalidGraphBanner extends ConsumerWidget {
  const InvalidGraphBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esInvalido = ref.watch(esGrafoInvalidoProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!esInvalido) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(
        Icons.gpp_maybe_rounded,
        color: colorScheme.error,
        size: 24,
      ),
      tooltip: 'Grafo Inválido',
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.errorContainer,
            content: Row(
              children: [
                Icon(
                  Icons.gpp_maybe_rounded,
                  color: colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Grafo Inválido: Hay nodos o componentes desconectados.',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

class _MockGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _MockGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}

@Preview(
  name: 'InvalidGraphBanner - Single Disconnected Node',
  group: 'Widgets',
)
Widget invalidGraphBannerSinglePreview() {
  const nodeA = Nodo(
    id: 'n1',
    x: 0,
    y: 0,
    colorValue: 0xFF2196F3,
    nombre: 'Nodo A',
  );
  final sampleGrafo = Grafo(nodos: {'n1': nodeA});

  return ProviderScope(
    overrides: [
      esGrafoInvalidoProvider.overrideWithValue(true),
      nodosDesconectadosProvider.overrideWithValue({'n1'}),
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGrafo)),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: InvalidGraphBanner())),
    ),
  );
}

@Preview(
  name: 'InvalidGraphBanner - Multiple Disconnected Nodes',
  group: 'Widgets',
)
Widget invalidGraphBannerMultiplePreview() {
  const nodeA = Nodo(
    id: 'n1',
    x: 0,
    y: 0,
    colorValue: 0xFF2196F3,
    nombre: 'Nodo A',
  );
  const nodeB = Nodo(
    id: 'n2',
    x: 100,
    y: 100,
    colorValue: 0xFF4CAF50,
    nombre: 'Nodo B',
  );
  final sampleGrafo = Grafo(nodos: {'n1': nodeA, 'n2': nodeB});

  return ProviderScope(
    overrides: [
      esGrafoInvalidoProvider.overrideWithValue(true),
      nodosDesconectadosProvider.overrideWithValue({'n1', 'n2'}),
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGrafo)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: Center(child: InvalidGraphBanner())),
    ),
  );
}
