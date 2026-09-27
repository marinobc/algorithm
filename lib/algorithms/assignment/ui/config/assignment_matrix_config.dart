import '../../../../ui/widgets/matrix/bipartite_matrix_config.dart';
import '../../domain/policy/assignment_graph_policy.dart';

class AssignmentMatrixConfig implements BipartiteMatrixConfig {
  const AssignmentMatrixConfig();

  @override
  String get title => 'Matriz de costos de asignación';

  @override
  String get subtitle => 'Bipartita: Orígenes (Filas) × Destinos (Columnas)';

  @override
  String get originHeaderTitle => 'Origen / Destino';

  @override
  String get destinationHeaderTitle => 'Destino';

  @override
  String get originRole => AssignmentRoles.origin;

  @override
  String get destinationRole => AssignmentRoles.destination;

  @override
  int get defaultOriginColor => AssignmentRoles.originColor;

  @override
  int get defaultDestinationColor => AssignmentRoles.destinationColor;

  @override
  String get costAttributeId => 'attr_valor';

  @override
  String get costCellHint => 'Costo';

  @override
  String get defaultTypeAlgorithm => 'assignment';

  @override
  bool get hasSuppliesAndDemands => false;

  @override
  bool get hasFictitiousBalancing => true;

  @override
  String get idPrefix => 'asg';
}
