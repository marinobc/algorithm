part of '../sorting_steps.dart';

SortingTimeline buildShellTimeline(List<int> input) {
  final values = List<int>.unmodifiable(input);
  final order = List<int>.generate(values.length, (index) => index);
  final slots = List<double>.generate(
    values.length,
    (index) => index.toDouble(),
  );
  final steps = <SortingStep>[];
  var comparisons = 0;
  var exchanges = 0;

  void add(
    SortingPhase phase,
    String message, {
    int? gap,
    int? currentId,
    int? comparingId,
    int sortedCount = 0,
    int durationMs = 210,
  }) {
    steps.add(
      SortingStep(
        slots: List<double>.unmodifiable(slots),
        phase: phase,
        sortedCount: sortedCount,
        currentId: currentId,
        comparingId: comparingId,
        minimumId: null,
        keyId: null,
        keyRaised: false,
        comparisons: comparisons,
        movements: exchanges,
        insertions: 0,
        durationMs: durationMs,
        message: message,
        gap: gap,
      ),
    );
  }

  add(SortingPhase.ready, 'Conjunto listo para ordenar.', durationMs: 0);
  if (values.isNotEmpty) {
    var gap = 1;
    while (gap < values.length ~/ 3) {
      gap = 3 * gap + 1;
    }
    while (gap >= 1) {
      add(
        SortingPhase.gap,
        'Inicia la pasada h=$gap: ${gap == 1 ? 'una subsecuencia' : '$gap subsecuencias intercaladas'}.',
        gap: gap,
        durationMs: 440,
      );
      for (var i = gap; i < order.length; i++) {
        for (var j = i; j >= gap; j -= gap) {
          final rightId = order[j];
          final leftId = order[j - gap];
          comparisons++;
          add(
            SortingPhase.comparing,
            'Posiciones ${j + 1} (${values[rightId]}) y ${j - gap + 1} (${values[leftId]}), h=$gap.',
            gap: gap,
            currentId: rightId,
            comparingId: leftId,
            durationMs: 330,
          );
          if (values[rightId] < values[leftId]) {
            order[j] = leftId;
            order[j - gap] = rightId;
            slots[rightId] = (j - gap).toDouble();
            slots[leftId] = j.toDouble();
            exchanges++;
            add(
              SortingPhase.swapping,
              'Intercambio: ${values[rightId]} va a ${j - gap + 1} y ${values[leftId]} va a ${j + 1}.',
              gap: gap,
              currentId: rightId,
              comparingId: leftId,
              durationMs: 470,
            );
          } else {
            add(
              SortingPhase.current,
              'Sin intercambio: ${values[rightId]} y ${values[leftId]} permanecen en sus posiciones.',
              gap: gap,
              currentId: rightId,
              comparingId: leftId,
              durationMs: 260,
            );
            break;
          }
        }
      }
      add(
        SortingPhase.sorted,
        'Pasada h=$gap completa: el arreglo está $gap-ordenado${gap == 1 ? ' y ordenado por completo' : ', aún no necesariamente ordenado por completo'}.',
        gap: gap,
        sortedCount: gap == 1 ? values.length : 0,
        durationMs: 500,
      );
      gap ~/= 3;
    }
  }
  add(
    SortingPhase.finished,
    'Ordenamiento finalizado.',
    sortedCount: values.length,
    durationMs: 180,
  );
  return SortingTimeline(
    algorithm: SortingAlgorithm.shell,
    values: values,
    steps: List<SortingStep>.unmodifiable(steps),
  );
}
