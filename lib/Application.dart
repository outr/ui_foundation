import 'dart:collection';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

import 'foundation.dart';

class Application<S, T extends AbstractTheme> extends StatefulWidget {
  final S state;
  final String title;
  final Widget Function() createHomeWidget;
  final TransitionManager transitionManager;

  final List<Screen> screens;
  final HistoryManager history;

  HashMap<Nav, int> navBadges = HashMap();
  T _theme;

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
      history = HistoryManager((initialScreen ?? screens.first).createState()),
      _theme = initialTheme,
      this.createHomeWidget = createHomeWidget ?? (() => Home()),
      this.transitionManager = transitionManager ?? TransitionManager.standard;

  @override
  State createState() => ApplicationState();

  Future<void> pushScreen(Screen screen) => push(screen.createState());

  Future<void> replaceScreen(Screen screen) => replace(screen.createState());

  Future<void> push(ScreenState state) {
    ScreenState current = history.current;
    if (state != current) {
      return history.push(state);
    } else {
      return Future.value(null);
    }
  }

  Future<void> replace(ScreenState state) {
    ScreenState current = history.current;
    if (state != current) {
      return history.replace(state);
    } else {
      return Future.value(null);
    }
  }

  Future<bool> back() {
    return history.back().then((value) {
      return value;
    });
  }

  Widget createTransition(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation) {
    return transitionManager.create(previous, current, direction, firstWidget, child, animation);
  }

  Duration getTransitionDuration(Screen? previous, Screen current, Direction? direction) {
    return transitionManager.duration(previous, current, direction);
  }

  void setNavBadge(Nav nav, int value) => instance.setState(() {
    navBadges[nav] = value;
  });

  Widget createNavIcon(Nav nav) {
    int value = navBadges[nav] ?? 0;
    Icon icon = Icon(nav.icon, size: 30);
    if (value == 0) {
      return icon;
    } else {
      return badges.Badge(
        child: icon,
        badgeStyle: badges.BadgeStyle(
          shape: badges.BadgeShape.circle,
          borderRadius: BorderRadius.circular(100),
        ),
        badgeContent: Text("$value", style: TextStyle(color: Colors.white)),
      );
    }
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