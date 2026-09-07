import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/edicion_provider.dart';
import '../../../application/providers/grafo_provider.dart';
import '../../../domain/models/conexion.dart';
import '../../../domain/models/direccion.dart';
import '../../../domain/models/grafo.dart';
import '../../../domain/models/nodo.dart';
import '../../theme/app_theme.dart';
import '../edit_panel.dart';

class _MockEdicionNotifier extends EdicionNotifier {
  final EstadoEdicion _initial;
  _MockEdicionNotifier(this._initial);

  @override
  EstadoEdicion build() => _initial;
}

class _MockGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _MockGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}

@Preview(name: 'EditPanel - Node Selected (Dark)', group: 'Widgets')
Widget editPanelNodeSelectedDarkPreview() {
  const sampleNode = Nodo(
    id: 'n1',
    x: 0,
    y: 0,
    colorValue: 0xFF2196F3,
    nombre: 'Nodo de Prueba',
  );
  final sampleGrafo = Grafo(nodos: {'n1': sampleNode});

  return ProviderScope(
    overrides: [
      estadoEdicionProvider.overrideWith(
        () => _MockEdicionNotifier(
          const EstadoEdicion(itemSeleccionadoId: 'n1', esNodo: true),
        ),
      ),
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGrafo)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: EditPanel()),
      ),
    ),
  );
}

@Preview(name: 'EditPanel - Node Selected (Light)', group: 'Widgets')
Widget editPanelNodeSelectedLightPreview() {
  const sampleNode = Nodo(
    id: 'n1',
    x: 0,
    y: 0,
    colorValue: 0xFF2196F3,
    nombre: 'Nodo de Prueba',
  );
  final sampleGrafo = Grafo(nodos: {'n1': sampleNode});

  return ProviderScope(
    overrides: [
      estadoEdicionProvider.overrideWith(
        () => _MockEdicionNotifier(
          const EstadoEdicion(itemSeleccionadoId: 'n1', esNodo: true),
        ),
      ),
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGrafo)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: EditPanel()),
      ),
    ),
  );
}

@Preview(name: 'EditPanel - Connection Selected (Dark)', group: 'Widgets')
Widget editPanelConnectionSelectedDarkPreview() {
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
  const conn1 = Conexion(
    id: 'c1',
    nodoOrigenId: 'n1',
    nodoDestinoId: 'n2',
    colorValue: 0xFF2196F3,
    direccion: Direccion.unidireccional,
  );
  final sampleGrafo = Grafo(
    nodos: {'n1': nodeA, 'n2': nodeB},
    conexiones: {'c1': conn1},
  );

  return ProviderScope(
    overrides: [
      estadoEdicionProvider.overrideWith(
        () => _MockEdicionNotifier(
          const EstadoEdicion(itemSeleccionadoId: 'c1', esNodo: false),
        ),
      ),
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGrafo)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: EditPanel()),
      ),
    ),
  );
}

@Preview(name: 'EditPanel - Connection Selected (Light)', group: 'Widgets')
Widget editPanelConnectionSelectedLightPreview() {
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
  const conn1 = Conexion(
    id: 'c1',
    nodoOrigenId: 'n1',
    nodoDestinoId: 'n2',
    colorValue: 0xFF2196F3,
    direccion: Direccion.unidireccional,
  );
  final sampleGrafo = Grafo(
    nodos: {'n1': nodeA, 'n2': nodeB},
    conexiones: {'c1': conn1},
  );

  return ProviderScope(
    overrides: [
      estadoEdicionProvider.overrideWith(
        () => _MockEdicionNotifier(
          const EstadoEdicion(itemSeleccionadoId: 'c1', esNodo: false),
        ),
      ),
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGrafo)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: EditPanel()),
      ),
    ),
  );
}
