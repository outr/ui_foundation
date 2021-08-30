import 'Screen.dart';

class ScreenState {
  final Screen screen;

  ScreenState(this.screen);

  @override
  int get hashCode => screen.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is ScreenState) {
      return screen == other.screen;
    }
    return false;
  }

  @override
  String toString() => 'ScreenState($screen)';
}