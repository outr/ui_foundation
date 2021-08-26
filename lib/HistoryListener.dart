import 'foundation.dart';

abstract class HistoryListener {
  void apply(HistoryAction action, ScreenState previous, ScreenState current);
}