import 'foundation.dart';

abstract class ScreenManager {
  void activating(ApplicationState appState, ScreenState state);

  void deactivating(ApplicationState appState, ScreenState state);

  /// Only keeps a single instance that is the last activated state of the screen.
  static final ScreenManager mostRecent = MostRecentScreenManager();

  /// Removes states after they are deactivated.
  static final ScreenManager onlyActive = OnlyActiveScreenManager();

  // TODO: keepDefault to only cache the default state of the screen
}

class MostRecentScreenManager extends ScreenManager {
  @override
  void activating(ApplicationState appState, ScreenState state) {
    appState.stack.keys.forEach((s) {
      if (s.screen == state.screen && s != state) {
        appState.stack.remove(s);
      }
    });
  }

  @override
  void deactivating(ApplicationState appState, ScreenState state) {}
}

class OnlyActiveScreenManager extends ScreenManager {
  @override
  void activating(ApplicationState appState, ScreenState state) {}

  @override
  void deactivating(ApplicationState appState, ScreenState state) {
    appState.stack.keys.forEach((s) {
      if (s.screen == state.screen) {
        print('*** Removing: $s');
        appState.stack.remove(s);
      }
    });
  }
}