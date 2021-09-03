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

  static final ScreenState stub = StubScreenState();
}

class StubScreenState extends ScreenState {
  StubScreenState():
    super(Screen(
        name: "STUB",
        create: (state) => throw Exception('StubScreenState cannot be used!')
      ));
}