import 'foundation.dart';

class HistoryManager {
  final List<HistoryState> _entries;
  final List<HistoryListener> _listeners = [];

  HistoryManager(HistoryState initialState):
        _entries = [initialState];

  bool get isTop => _entries.length == 1;

  HistoryState get current => _entries.last;
  HistoryState? get previous {
    if (_entries.length > 1) {
      return _entries[_entries.length - 2];
    } else {
      return null;
    }
  }

  Future<void> push(HistoryState state) {
    final HistoryState previous = current;
    _entries.add(state);
    _invokeListeners(HistoryAction.push, previous, state);
    return Future.value(null);
  }

  Future<void> replace(HistoryState state) {
    final HistoryState previous = current;
    _entries.removeLast();
    _entries.add(state);
    _invokeListeners(HistoryAction.replace, previous, state);
    return Future.value(null);
  }

  Future<bool> back() {
    if (isTop) {
      return Future.value(false);
    }
    final HistoryState previous = _entries.removeLast();
    _invokeListeners(HistoryAction.back, previous, current);
    return Future.value(true);
  }

  void listen(HistoryListener listener) {
    _listeners.add(listener);
  }

  void remove(HistoryListener listener) {
    _listeners.remove(listener);
  }

  void _invokeListeners(HistoryAction action, HistoryState previous, HistoryState current) {
    _listeners.forEach((listener) => listener.apply(action, previous, current));
  }
}