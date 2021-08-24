import 'foundation.dart';

abstract class HistoryListener<V> {
  void apply(HistoryAction action, HistoryState<V> previous, HistoryState<V> current);
}