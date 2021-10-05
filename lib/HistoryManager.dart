import 'foundation.dart';

class HistoryManager {
  final List<ScreenState> _entries;
  final List<HistoryListener> _listeners = [];

  HistoryManager(ScreenState initialState):
    _entries = [initialState] {
    initialState.screen.active = true;
    initialState.screen.activated(HistoryAction.push);
  }

  bool get isTop => _entries.length == 1;

  ScreenState get current => _entries.last;
  ScreenState? get previous {
    if (_entries.length > 1) {
      return _entries[_entries.length - 2];
    } else {
      return null;
    }
  }

  Future<void> push(ScreenState state) {
    final ScreenState previous = current;
    _entries.add(state);
    _invokeListeners(HistoryAction.push, previous, state);
    return Future.value(null);
  }

  Future<void> replace(ScreenState state) {
    final ScreenState previous = current;
    _entries.removeLast();
    _entries.add(state);
    _invokeListeners(HistoryAction.replace, previous, state);
    return Future.value(null);
  }

  Future<bool> back() {
    if (isTop) {
      return Future.value(false);
    }
    final ScreenState previous = _entries.removeLast();
    _invokeListeners(HistoryAction.back, previous, current);
    return Future.value(true);
  }

  void listen(HistoryListener listener) {
    _listeners.add(listener);
  }

  void remove(HistoryListener listener) {
    _listeners.remove(listener);
  }

  void _invokeListeners(HistoryAction action, ScreenState previous, ScreenState current) {
    previous.screen.active = false;
    current.screen.active = true;

    previous.screen.deactivated(action);
    current.screen.activated(action);
    _listeners.forEach((listener) => listener.apply(action, previous, current));
  }
}