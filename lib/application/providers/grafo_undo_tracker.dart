import '../../domain/models/grafo.dart';

/// Helper managing undo/redo snapshots and saved checkpoints for GrafoNotifier.
class GrafoUndoTracker {
  final List<Grafo> _undoStack = [];
  final List<Grafo> _redoStack = [];
  Grafo? _lastSavedGraphState;

  bool get puedeDeshacer => _undoStack.isNotEmpty;
  bool get puedeRehacer => _redoStack.isNotEmpty;

  bool tieneCambiosSinGuardar(Grafo currentState) {
    final saved = _lastSavedGraphState;
    if (saved == null) {
      return currentState.nodos.isNotEmpty || _undoStack.isNotEmpty;
    }
    return currentState != saved;
  }

  void marcarPuntoGuardado(Grafo currentState) {
    _lastSavedGraphState = currentState;
  }

  void recordUndoState(Grafo currentState) {
    _undoStack.add(currentState);
    _redoStack.clear();
  }

  Grafo? deshacer(Grafo currentState) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(currentState);
    return _undoStack.removeLast();
  }

  Grafo? rehacer(Grafo currentState) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(currentState);
    return _redoStack.removeLast();
  }

  void clear(Grafo initialSavedState) {
    _undoStack.clear();
    _redoStack.clear();
    _lastSavedGraphState = initialSavedState;
  }
}
