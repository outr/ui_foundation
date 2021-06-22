import 'foundation.dart';

class HistoryState {
  final Screen screen;
  final Arguments args;

  HistoryState(this.screen, this.args);

  @override
  int get hashCode => screen.hashCode + args.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is HistoryState) {
      return screen == other.screen && args == other.args;
    }
    return false;
  }

  @override
  String toString() => '$screen ($args)';
}