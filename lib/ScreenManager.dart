import 'foundation.dart';

abstract class ScreenManager {
  void activating(ApplicationState appState, ScreenState state);

  static ScreenManager singleton = SingletonScreenManager();
}

class SingletonScreenManager extends ScreenManager {
  @override
  void activating(ApplicationState appState, ScreenState state) {
    print('Singleton activating screen!');
    appState.stack.keys.forEach((s) {
      if (s.screen == state.screen && s != state) {
        print('Removing previous screen state: $s');
        appState.stack.remove(s);
      }
    });
  }
}