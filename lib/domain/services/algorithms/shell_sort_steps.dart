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
  var shifts = 0;
  var insertions = 0;

  void add(
    SortingPhase phase,
    String message, {
    int? gap,
    int? keyId,
    int? comparingId,
    bool keyRaised = false,
    int sortedCount = 0,
    int durationMs = 210,
  }) {
    steps.add(
      SortingStep(
        slots: List<double>.unmodifiable(slots),
        phase: phase,
        sortedCount: sortedCount,
        currentId: null,
        comparingId: comparingId,
        minimumId: null,
        keyId: keyId,
        keyRaised: keyRaised,
        comparisons: comparisons,
        movements: shifts,
        insertions: insertions,
        durationMs: durationMs,
        message: message,
        gap: gap,
      ),
    );
  }

  add(SortingPhase.ready, 'Conjunto listo para ordenar.', durationMs: 0);
  if (values.isNotEmpty) {
    var gap = 1;
    while (gap * 3 < values.length) {
      gap = gap * 3 + 1;
    }
    while (gap >= 1) {
      add(SortingPhase.gap, 'Ordenando subsecuencias con gap $gap.', gap: gap);
      for (var i = gap; i < order.length; i++) {
        final keyId = order[i];
        add(
          SortingPhase.key,
          'Seleccionando ${values[keyId]} con gap $gap.',
          gap: gap,
          keyId: keyId,
          keyRaised: true,
        );
        var j = i;
        while (j >= gap) {
          final comparedId = order[j - gap];
          comparisons++;
          add(
            SortingPhase.comparing,
            'Comparando ${values[keyId]} con ${values[comparedId]} a distancia $gap.',
            gap: gap,
            keyId: keyId,
            comparingId: comparedId,
            keyRaised: true,
          );
          if (values[comparedId] <= values[keyId]) break;
          order[j] = comparedId;
          slots[comparedId] = j.toDouble();
          shifts++;
          add(
            SortingPhase.shifting,
            '${values[comparedId]} se desplaza $gap posiciones.',
            gap: gap,
            keyId: keyId,
            comparingId: comparedId,
            keyRaised: true,
            durationMs: 310,
          );
          j -= gap;
        }
        order[j] = keyId;
        slots[keyId] = j.toDouble();
        insertions++;
        add(
          SortingPhase.inserting,
          'Insertando ${values[keyId]} en la posición ${j + 1}.',
          gap: gap,
          keyId: keyId,
          keyRaised: true,
          durationMs: 330,
        );
      }
      if (gap == 1) break;
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
