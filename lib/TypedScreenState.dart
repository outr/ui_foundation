import 'foundation.dart';

class TypedScreenState<V> extends ScreenState {
  final V value;

  TypedScreenState(Screen screen, this.value):
        super(screen);

  @override
  int get hashCode => screen.hashCode + value.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is TypedScreenState) {
      return screen == other.screen && value == other.value;
    }
    return false;
  }

  @override
  String toString() => 'TypedScreenState($screen, $value)';
}