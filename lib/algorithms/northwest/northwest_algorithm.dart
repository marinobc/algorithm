import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../../ui/dialogs/connection_value_input_dialog.dart';
import '../../ui/screens/graph_editor_screen.dart';
import '../core/algorithm_registry.dart';
import '../core/graph_algorithm.dart';
import 'domain/policy/northwest_graph_policy.dart';
import 'providers/northwest_provider.dart';
import 'ui/northwest_algorithm_widgets.dart';
import 'ui/northwest_matrix_screen.dart';
import 'ui/northwest_node_input_dialog.dart';

class NorthwestAlgorithm implements GraphAlgorithm {
  static const String algorithmId = 'northwest';

  const NorthwestAlgorithm();

  @override
  String get id => algorithmId;

  @override
  String get name => 'Northwest';

  @override
  String get shortName => 'Northwest';

  @override
  String get description =>
      'Resuelve problemas de transporte mediante esquina noroeste y optimizacion MODI.';

  @override
  IconData get icon => Icons.grid_view_rounded;

  @override
  Color get themeColor => const Color(0xFFE54872);

  @override
  String get userGuideMarkdown => r'''
# Guía de Uso: Algoritmo Esquina Noroeste (Transporte)

El **Algoritmo de Esquina Noroeste** determina una solución básica factible inicial para modelos de transporte y distribución de mercancías, combinándose con el **Método MODI** para alcanzar la solución óptima.

---

## 1. Definición de Red, Oferta y Demanda
- **Fuentes / Orígenes (Oferta $a_i$):** Nodos que producen o proveen bienes. Se ingresa la capacidad de oferta en las propiedades del nodo.
- **Destinos (Demanda $b_j$):** Nodos que reciben o consumen bienes. Se ingresa la demanda requerida en las propiedades del nodo.
- **Costos Unitarios de Transporte ($c_{ij}$):** El valor de cada arista indica el costo de transportar 1 unidad desde el origen $i$ al destino $j$.

---

## 2. Matriz de Transporte y Control de Balanceo
- **Pantalla Matricial Integrada:** Ofrece la vista completa de la tabla de transporte con controles dinámicos $+ / -$ para agregar filas u orígenes en caliente.
- **Verificación de Balanceo:** Si la oferta total no coincide con la demanda total ($\\sum a_i \\neq \\sum b_j$), el sistema balancea la tabla insertando un nodo ficticio de costo $0$.

---

## 3. Algoritmo Esquina Noroeste y Criterio MODI
- **Asignación Inicial:** Comienza en la celda $(1,1)$ (Esquina Noroeste) asignando el máximo número de unidades posibles y desplazándose a la derecha o abajo según se satisfagan capacidades.
- **Optimización MODI:** Calcula los multiplicadores $u_i$ y $v_j$ para evaluar celdas no básicas y optimizar el costo total del transporte.
''';

  @override
  GraphAlgorithmPolicy get policy => const NorthwestGraphPolicy();

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) {
    return NorthwestLaunchButton(
      onPressed: () {
        ref
            .read(activeAlgorithmProvider.notifier)
            .selectById(AlgorithmRegistry.northwestId);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
        );
      },
    );
  }

  @override
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) =>
      const NorthwestCanvasControls();

  @override
  Map<String, dynamic>? newNodeParams(WidgetRef ref) => {
    'role': ref.read(northwestActiveRoleProvider),
  };

  @override
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) => null;

  @override
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) {
    return ref.watch(northwestNotifierProvider).isActive
        ? const NorthwestAlgorithmCard()
        : null;
  }

  @override
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) {
    return NorthwestQuantityEditor(node: nodo);
  }

  @override
  bool get supportsMatrix => true;

  @override
  String? get matrixUnavailableReason => null;

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) =>
      const NorthwestMatrixScreen();

  @override
  Future<bool?> showConnectionValueInputDialog(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    return ConnectionValueInputDialog.show(
      context: context,
      ref: ref,
      conexion: conexion,
      title: 'Costo de Transporte (Esquina Noroeste)',
      valueLabel: 'Costo unitario de transporte (no negativo)',
    );
  }

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) async {
    final result = await showConnectionValueInputDialog(context, ref, conexion);
    if (result == true) {
      ref.read(northwestNotifierProvider.notifier).setActive(false);
    }
  }

  @override
  Future<void> onNodeCreated(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) async {
    final result = await NorthwestNodeInputDialog.show(context, ref, nodo);
    if (result == true) {
      ref.read(northwestNotifierProvider.notifier).setActive(false);
    }
  }
}
