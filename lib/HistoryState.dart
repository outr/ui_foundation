import 'foundation.dart';

class HistoryState<V> {
  final Screen<V> screen;
  final V value;

  HistoryState(this.screen, this.value);

  @override
  int get hashCode => screen.hashCode + value.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is HistoryState) {
      return screen == other.screen && value == other.value;
    }
    return false;
  }

  @override
  String toString() => '$screen ($value)';
}