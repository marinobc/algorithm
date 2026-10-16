part of '../sorting_steps.dart';

SortingTimeline buildMergeTimeline(List<int> input) {
  final values = List<int>.unmodifiable(input);
  final order = List<int>.generate(values.length, (index) => index);
  final slots = List<double>.generate(
    values.length,
    (index) => index.toDouble(),
  );
  final aux = List<int?>.filled(values.length, null);
  final steps = <SortingStep>[];
  final rootMiddle = values.length ~/ 2;
  var comparisons = 0;
  var writes = 0;
  var auxCopies = 0;
  var leftReady = false;
  var rightReady = false;

  SortingMergeState snapshot(
    SortingMergeStage stage,
    int start,
    int middle,
    int end,
    List<int> left,
    List<int> right,
    List<int> output, {
    int leftConsumed = 0,
    int rightConsumed = 0,
    int? selectedId,
    int? i,
    int? j,
    int? k,
  }) => SortingMergeState(
    stage: stage,
    rootMiddle: rootMiddle,
    rootLeftIds: List<int>.unmodifiable(order.sublist(0, rootMiddle)),
    rootRightIds: List<int>.unmodifiable(order.sublist(rootMiddle)),
    leftReady: leftReady,
    rightReady: rightReady,
    start: start,
    middle: middle,
    end: end,
    leftIds: List<int>.unmodifiable(left),
    rightIds: List<int>.unmodifiable(right),
    outputIds: List<int>.unmodifiable(output),
    arrayIds: List<int>.unmodifiable(order),
    auxIds: List<int?>.unmodifiable(aux),
    i: i,
    j: j,
    k: k,
    leftConsumed: leftConsumed,
    rightConsumed: rightConsumed,
    selectedId: selectedId,
  );

  void add(
    SortingPhase phase,
    String message,
    SortingMergeState state, {
    int? leftId,
    int? rightId,
    int sortedCount = 0,
    int durationMs = 260,
  }) {
    steps.add(
      SortingStep(
        slots: List<double>.unmodifiable(slots),
        phase: phase,
        sortedCount: sortedCount,
        currentId: leftId,
        comparingId: rightId,
        minimumId: null,
        keyId: null,
        keyRaised: false,
        comparisons: comparisons,
        movements: 0,
        insertions: 0,
        writes: writes,
        auxCopies: auxCopies,
        durationMs: durationMs,
        message: message,
        mergeState: state,
      ),
    );
  }

  SortingMergeState rootState(SortingMergeStage stage) => snapshot(
    stage,
    0,
    rootMiddle,
    values.length,
    order.sublist(0, rootMiddle),
    order.sublist(rootMiddle),
    [],
  );

  void focus(SortingMergeStage stage, String message) {
    add(SortingPhase.mergeFocus, message, rootState(stage), durationMs: 400);
  }

  add(
    SortingPhase.ready,
    'Conjunto listo para ordenar.',
    rootState(SortingMergeStage.ready),
    durationMs: 0,
  );

  void sort(int start, int end, SortingMergeStage stage, {bool root = false}) {
    if (end - start <= 1) return;
    final middle = start + (end - start) ~/ 2;
    add(
      SortingPhase.splitting,
      'Dividiendo posiciones ${start + 1}–$end en dos mitades.',
      snapshot(
        stage,
        start,
        middle,
        end,
        order.sublist(start, middle),
        order.sublist(middle, end),
        [],
      ),
      durationMs: 420,
    );

    if (root) focus(SortingMergeStage.left, 'Ordenando la mitad izquierda.');
    sort(start, middle, root ? SortingMergeStage.left : stage);
    if (root) {
      leftReady = true;
      focus(
        SortingMergeStage.right,
        'Mitad izquierda ordenada. Ahora sigue la derecha.',
      );
    }
    sort(middle, end, root ? SortingMergeStage.right : stage);
    if (root) {
      rightReady = true;
      focus(
        SortingMergeStage.fusion,
        'Ambas mitades están ordenadas. Comienza la fusión.',
      );
    }

    final left = List<int>.of(order.sublist(start, middle));
    final right = List<int>.of(order.sublist(middle, end));
    final output = <int>[];
    var l = 0;
    var r = 0;
    final mergeStage = root ? SortingMergeStage.fusion : stage;
    for (var index = start; index < end; index++) {
      aux[index] = order[index];
      auxCopies++;
    }
    add(
      SortingPhase.mergeCopying,
      'Copiando a aux[${start + 1}..$end] antes de fusionar.',
      snapshot(
        mergeStage,
        start,
        middle,
        end,
        left,
        right,
        output,
        i: start,
        j: middle,
        k: start,
      ),
      durationMs: 390,
    );
    while (l < left.length || r < right.length) {
      if (l < left.length && r < right.length) {
        comparisons++;
        add(
          SortingPhase.mergeComparing,
          'Comparando ${values[left[l]]} y ${values[right[r]]}.',
          snapshot(
            mergeStage,
            start,
            middle,
            end,
            left,
            right,
            output,
            leftConsumed: l,
            rightConsumed: r,
            i: start + l,
            j: middle + r,
            k: start + output.length,
          ),
          leftId: left[l],
          rightId: right[r],
          durationMs: 320,
        );
      }
      final leftExhausted = l >= left.length;
      final rightExhausted = r >= right.length;
      final chosen =
          rightExhausted ||
              (!leftExhausted && values[left[l]] <= values[right[r]])
          ? left[l++]
          : right[r++];
      final target = start + output.length;
      order[target] = chosen;
      output.add(chosen);
      writes++;
      add(
        SortingPhase.mergeWriting,
        '${leftExhausted || rightExhausted ? 'Mitad agotada; copiando' : 'Escribiendo'} ${values[chosen]} en a[${target + 1}].',
        snapshot(
          mergeStage,
          start,
          middle,
          end,
          left,
          right,
          output,
          leftConsumed: l,
          rightConsumed: r,
          selectedId: chosen,
          i: start + l,
          j: middle + r,
          k: target,
        ),
        leftId: chosen,
        durationMs: 460,
      );
    }
    for (var offset = 0; offset < output.length; offset++) {
      slots[output[offset]] = (start + offset).toDouble();
    }
    add(
      SortingPhase.merged,
      'Posiciones ${start + 1}–$end fusionadas en orden.',
      snapshot(
        mergeStage,
        start,
        middle,
        end,
        left,
        right,
        output,
        leftConsumed: l,
        rightConsumed: r,
        i: start + l,
        j: middle + r,
        k: end,
      ),
      sortedCount: root ? values.length : 0,
      durationMs: 300,
    );
  }

  if (values.length > 1) {
    sort(0, values.length, SortingMergeStage.division, root: true);
  }
  add(
    SortingPhase.finished,
    'Ordenamiento finalizado.',
    snapshot(
      SortingMergeStage.result,
      0,
      rootMiddle,
      values.length,
      order.sublist(0, rootMiddle),
      order.sublist(rootMiddle),
      order,
    ),
    sortedCount: values.length,
    durationMs: 250,
  );
  return SortingTimeline(
    algorithm: SortingAlgorithm.merge,
    values: values,
    steps: List<SortingStep>.unmodifiable(steps),
  );
}
