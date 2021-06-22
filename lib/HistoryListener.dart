import 'foundation.dart';

abstract class HistoryListener {
  void apply(HistoryAction action, HistoryState previous, HistoryState current);
}