enum SortingAlgorithm { selection, insertion }

enum SortingPhase {
  ready,
  current,
  comparing,
  minimum,
  swapping,
  sorted,
  key,
  shifting,
  inserting,
  finished,
}

class SortingStep {
  final List<double> slots;
  final SortingPhase phase;
  final int sortedCount;
  final int? currentId;
  final int? comparingId;
  final int? minimumId;
  final int? keyId;
  final bool keyRaised;
  final int comparisons;
  final int movements;
  final int insertions;
  final int durationMs;
  final String message;

  const SortingStep({
    required this.slots,
    required this.phase,
    required this.sortedCount,
    required this.currentId,
    required this.comparingId,
    required this.minimumId,
    required this.keyId,
    required this.keyRaised,
    required this.comparisons,
    required this.movements,
    required this.insertions,
    required this.durationMs,
    required this.message,
  });
}

class SortingTimeline {
  final SortingAlgorithm algorithm;
  final List<int> values;
  final List<SortingStep> steps;

  const SortingTimeline({
    required this.algorithm,
    required this.values,
    required this.steps,
  });

  static SortingTimeline build(SortingAlgorithm algorithm, List<int> input) {
    final values = List<int>.unmodifiable(input);
    final order = List<int>.generate(values.length, (index) => index);
    final slots = List<double>.generate(
      values.length,
      (index) => index.toDouble(),
    );
    final steps = <SortingStep>[];
    var comparisons = 0;
    var movements = 0;
    var insertions = 0;

    void add(
      SortingPhase phase,
      String message, {
      int sortedCount = 0,
      int? currentId,
      int? comparingId,
      int? minimumId,
      int? keyId,
      bool keyRaised = false,
      int durationMs = 210,
    }) {
      steps.add(
        SortingStep(
          slots: List<double>.unmodifiable(slots),
          phase: phase,
          sortedCount: sortedCount,
          currentId: currentId,
          comparingId: comparingId,
          minimumId: minimumId,
          keyId: keyId,
          keyRaised: keyRaised,
          comparisons: comparisons,
          movements: movements,
          insertions: insertions,
          durationMs: durationMs,
          message: message,
        ),
      );
    }

    add(SortingPhase.ready, 'Conjunto listo para ordenar.', durationMs: 0);
    if (algorithm == SortingAlgorithm.selection) {
      for (var i = 0; i < order.length; i++) {
        var min = i;
        add(
          SortingPhase.current,
          'Buscando el menor elemento desde la posición ${i + 1}.',
          sortedCount: i,
          currentId: order[i],
          minimumId: order[min],
        );
        for (var j = i + 1; j < order.length; j++) {
          comparisons++;
          add(
            SortingPhase.comparing,
            'Comparando ${values[order[j]]} con ${values[order[min]]}.',
            sortedCount: i,
            currentId: order[i],
            comparingId: order[j],
            minimumId: order[min],
          );
          if (values[order[j]] < values[order[min]]) {
            min = j;
            add(
              SortingPhase.minimum,
              '${values[order[min]]} es el nuevo mínimo.',
              sortedCount: i,
              currentId: order[i],
              minimumId: order[min],
              durationMs: 200,
            );
          }
        }
        if (min != i) {
          final leftId = order[i];
          final rightId = order[min];
          order[i] = rightId;
          order[min] = leftId;
          slots[leftId] = min.toDouble();
          slots[rightId] = i.toDouble();
          movements++;
          add(
            SortingPhase.swapping,
            'Intercambiando ${values[leftId]} con ${values[rightId]}.',
            sortedCount: i,
            currentId: leftId,
            minimumId: rightId,
            durationMs: 420,
          );
        }
        add(
          SortingPhase.sorted,
          'La posición ${i + 1} queda ordenada.',
          sortedCount: i + 1,
          durationMs: 180,
        );
      }
    } else {
      if (order.isNotEmpty) {
        add(
          SortingPhase.sorted,
          'La primera posición inicia la región ordenada.',
          sortedCount: 1,
          durationMs: 180,
        );
      }
      for (var i = 1; i < order.length; i++) {
        final keyId = order[i];
        add(
          SortingPhase.key,
          'Seleccionando ${values[keyId]} como elemento clave.',
          sortedCount: i,
          keyId: keyId,
          keyRaised: true,
          durationMs: 240,
        );
        var j = i - 1;
        while (j >= 0) {
          final comparedId = order[j];
          comparisons++;
          add(
            SortingPhase.comparing,
            'Comparando ${values[keyId]} con ${values[comparedId]}.',
            sortedCount: i,
            comparingId: comparedId,
            keyId: keyId,
            keyRaised: true,
          );
          if (values[comparedId] <= values[keyId]) break;
          order[j + 1] = comparedId;
          slots[comparedId] = (j + 1).toDouble();
          movements++;
          add(
            SortingPhase.shifting,
            '${values[comparedId]} se desplaza una posición a la derecha.',
            sortedCount: i,
            comparingId: comparedId,
            keyId: keyId,
            keyRaised: true,
            durationMs: 310,
          );
          j--;
        }
        order[j + 1] = keyId;
        slots[keyId] = (j + 1).toDouble();
        insertions++;
        add(
          SortingPhase.inserting,
          'Insertando ${values[keyId]} en la posición ${j + 2}.',
          sortedCount: i,
          keyId: keyId,
          keyRaised: true,
          durationMs: 330,
        );
        add(
          SortingPhase.sorted,
          'Las primeras ${i + 1} posiciones quedan ordenadas.',
          sortedCount: i + 1,
          durationMs: 180,
        );
      }
    }

    add(
      SortingPhase.finished,
      'Ordenamiento finalizado.',
      sortedCount: values.length,
      durationMs: 180,
    );
    return SortingTimeline(
      algorithm: algorithm,
      values: values,
      steps: List<SortingStep>.unmodifiable(steps),
    );
  }
}
