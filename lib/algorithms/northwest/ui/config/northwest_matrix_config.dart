import '../../../../ui/widgets/matrix/bipartite_matrix_config.dart';
import '../../domain/services/northwest_problem_extractor.dart';

class NorthwestMatrixConfig implements BipartiteMatrixConfig {
  const NorthwestMatrixConfig();

  @override
  String get title => 'Matriz de transporte y esquina noroeste';

  @override
  String get subtitle => 'Orígenes (Oferta) × Destinos (Demanda)';

  @override
  String get originHeaderTitle => 'Origen / Destino';

  @override
  String get destinationHeaderTitle => 'Destino';

  @override
  String get originRole => NorthwestRoles.origin;

  @override
  String get destinationRole => NorthwestRoles.destination;

  @override
  int get defaultOriginColor => 0xFF2196F3;

  @override
  int get defaultDestinationColor => 0xFF4CAF50;

  @override
  String get costAttributeId => 'attr_valor';

  @override
  String get costCellHint => 'Costo';

  @override
  String get defaultTypeAlgorithm => 'northwest';

  @override
  bool get hasSuppliesAndDemands => true;

  @override
  bool get hasFictitiousBalancing => true;

  @override
  String get idPrefix => 'nw';
}
