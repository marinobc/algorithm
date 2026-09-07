import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_provider.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../theme/app_theme.dart';
import 'graph_canvas.dart';

class _MockGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _MockGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}

@Preview(name: 'GraphCanvas - Sample Graph', group: 'Canvas')
Widget graphCanvasPreview() {
  final sampleGraph = Grafo(
    nodos: {
      'n1': const Nodo(
        id: 'n1',
        x: -100,
        y: -50,
        nombre: 'Nodo A',
        colorValue: 0xFF2196F3,
      ),
      'n2': const Nodo(
        id: 'n2',
        x: 100,
        y: -50,
        nombre: 'Nodo B',
        colorValue: 0xFF4CAF50,
      ),
      'n3': const Nodo(
        id: 'n3',
        x: 0,
        y: 100,
        nombre: 'Nodo C',
        colorValue: 0xFFFF9800,
      ),
    },
    conexiones: {
      'c1': const Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        direccion: Direccion.unidireccional,
        colorValue: 0xFF2196F3,
      ),
      'c2': const Conexion(
        id: 'c2',
        nodoOrigenId: 'n2',
        nodoDestinoId: 'n3',
        direccion: Direccion.bidireccional,
        colorValue: 0xFF4CAF50,
      ),
    },
  );

  return ProviderScope(
    overrides: [
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGraph)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: GraphCanvas()),
    ),
  );
}
