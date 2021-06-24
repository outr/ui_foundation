import 'package:flutter/material.dart';

import 'foundation.dart';

class Application<S, T extends AbstractTheme> extends StatefulWidget {
  final S state;
  final String title;
  final Widget Function() createHomeWidget;
  final TransitionManager transitionManager;

  final List<Screen> screens;
  final HistoryManager history;

  T _theme;

  Screen get screen => history.current.screen;
  Arguments get args => history.current.args;

  T get theme => _theme;
  set theme(T theme) {
    _theme = theme;
    instance.setState(() {});
    reloadAll();
  }

  static ApplicationState get instance => of(staticContext!)!;

  Application({
    required this.state,
    required this.title,
    required T initialTheme,
    Screen? initialScreen,
    required this.screens,
    Widget Function()? createHomeWidget,
    TransitionManager? transitionManager
  }):
      history = HistoryManager(HistoryState(initialScreen ?? screens.first, Arguments.empty)),
      _theme = initialTheme,
      this.createHomeWidget = createHomeWidget ?? (() => Home()),
      this.transitionManager = transitionManager ?? TransitionManager.standard;

  @override
  State createState() => ApplicationState();

  Future<void> push(Screen screen, {Arguments? args}) {
    final Arguments arguments = args ?? Arguments.empty;
    HistoryState current = history.current;
    if (current.screen != screen || current.args != arguments) {
      return history
        .push(HistoryState(screen, arguments))
        .then((value) => instance.setState(() {}));
    } else {
      return Future.value(null);
    }
  }

  Future<void> replace(Screen screen, {Arguments? args}) {
    final Arguments arguments = args ?? Arguments.empty;
    HistoryState current = history.current;
    if (current.screen == screen && current.args == arguments) {
      return Future.value(null);
    } else {
      return history
        .replace(HistoryState(screen, args ?? Arguments.empty))
        .then((value) => instance.setState(() {}));
    }
  }

  Future<bool> back() {
    return history.back().then((value) {
      instance.setState(() {});
      return value;
    });
  }

  Widget createTransition(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation) {
    return transitionManager.create(previous, current, direction, firstWidget, child, animation);
  }

  Duration getTransitionDuration(Screen? previous, Screen current, Direction? direction) {
    return transitionManager.duration(previous, current, direction);
  }

  void reloadAll() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }
    (staticContext as Element).visitChildren(rebuild);
  }

  Direction? direction(Screen? s1, Screen s2) {
    if (s1 == null) {
      return null;
    } else {
      if (s1 == s2) return null;
      final Nav? n1 = s1.getNav();
      final Nav? n2 = s2.getNav();
      if (n1 != null && n2 != null && n1.bar == n2.bar) {
        final NavBar bar = n1.bar;
        final List<Screen> screens = this.screens.where((s) => s.hasNavBar(bar)).toList(growable: false);
        final int i1 = screens.indexOf(s1.getNavScreen()!);
        final int i2 = screens.indexOf(s2.getNavScreen()!);
        if (i1 < i2) {
          return Direction.forward;
        } else if (i1 > i2) {
          return Direction.back;
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
  }

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static BuildContext? get staticContext => navKey.currentContext;

  static ApplicationState? of(BuildContext context, {bool root = false}) => root
      ? context.findRootAncestorStateOfType<ApplicationState>()
      : context.findAncestorStateOfType<ApplicationState>();
}