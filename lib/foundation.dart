library foundation;

import 'package:flutter/material.dart';

class NavBar {
}

class Nav {
  final String label;
  final IconData icon;
  final NavBar bar;

  Nav(this.label, this.icon, this.bar);
}

class Screen extends ScreenListener {
  final String name;
  final Nav? nav;
  final Screen? parent;
  final Widget Function(Arguments) create;
  final ScreenCacheManager? cacheManager;

  final Map<Arguments, Widget> _cacheMap = {};
  final List<ScreenListener> _listeners = [];

  Screen({
    required this.name,
    required this.create,
    this.nav,
    this.parent,
    this.cacheManager
  }) {
    listen(this);
  }

  Widget get(Arguments args) {
    final Widget? cached = this.cached(args);
    if (cached != null) {
      return cached;
    } else {
      final Widget w = create(args);
      invokeListeners(ScreenState.created, w, args);
      cacheManager?.cache(this, w, args);
      return w;
    }
  }

  Widget? cached(Arguments args) => _cacheMap[args];

  Nav? getNav() => nav ?? parent?.getNav();

  Screen? getNavScreen() {
    if (nav != null) {
      return this;
    } else {
      return parent?.getNavScreen();
    }
  }

  bool hasNavBar(NavBar bar) => nav?.bar == bar;

  void addToCache(Widget widget, Arguments args) {
    final Widget? existing = _cacheMap[args];
    _cacheMap[args] = widget;
    if (existing != null) {
      invokeListeners(ScreenState.disposed, existing, args);
    }
  }

  void removeFromCache(Widget widget, Arguments args) {
    final Widget? removed = _cacheMap.remove(args);
    if (removed != null) {
      invokeListeners(ScreenState.disposed, removed, args);
    }
  }

  void clearCache() {
    _cacheMap.forEach((args, widget) => removeFromCache(widget, args));
  }

  void listen(ScreenListener listener) {
    _listeners.add(listener);
  }

  void remove(ScreenListener listener) {
    _listeners.remove(listener);
  }

  void invokeListeners(ScreenState state, Widget? widget, Arguments args) {
    _listeners.forEach((listener) => listener.apply(this, state, widget, args));
  }

  @override
  void apply(Screen screen, ScreenState state, Widget? widget, Arguments args) {
    if (state == ScreenState.disposed && widget != null) {
      Application.instance.children.remove(widget);
    }
  }

  @override
  String toString() => 'Screen($name)';
}

abstract class ScreenListener {
  void apply(Screen screen, ScreenState state, Widget? widget, Arguments args);
}

enum ScreenState {
  created,
  activated,
  deactivated,
  disposed
}

class HistoryManager {
  final List<HistoryState> _entries;
  final List<HistoryListener> _listeners = [];

  HistoryManager(HistoryState initialState):
    _entries = [initialState];

  bool get isTop => _entries.length == 1;

  HistoryState get current => _entries.last;
  HistoryState? get previous {
    if (_entries.length > 1) {
      return _entries[_entries.length - 2];
    } else {
      return null;
    }
  }

  Future<void> push(HistoryState state) {
    final HistoryState previous = current;
    _entries.add(state);
    _invokeListeners(HistoryAction.push, previous, state);
    return Future.value(null);
  }

  Future<void> replace(HistoryState state) {
    final HistoryState previous = current;
    _entries.removeLast();
    _entries.add(state);
    _invokeListeners(HistoryAction.replace, previous, state);
    return Future.value(null);
  }

  Future<bool> back() {
    if (isTop) {
      return Future.value(false);
    }
    final HistoryState previous = _entries.removeLast();
    _invokeListeners(HistoryAction.back, previous, current);
    return Future.value(true);
  }

  void listen(HistoryListener listener) {
    _listeners.add(listener);
  }

  void remove(HistoryListener listener) {
    _listeners.remove(listener);
  }

  void _invokeListeners(HistoryAction action, HistoryState previous, HistoryState current) {
    _listeners.forEach((listener) => listener.apply(action, previous, current));
  }
}

abstract class HistoryListener {
  void apply(HistoryAction action, HistoryState previous, HistoryState current);
}

enum HistoryAction {
  push,
  replace,
  back
}

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

class Arguments {
  final Map<String, String> map;

  Arguments(this.map);

  static Arguments empty = Arguments({});

  @override
  int get hashCode => map.toString().hashCode;

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  String toString() => map.toString();
}

abstract class ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args);

  static final ScreenCacheManager never = _NeverCacheManager();
  static final ScreenCacheManager always = _AlwaysCacheManager();
  static final ScreenCacheManager one = _OneCacheManager();
}

class _NeverCacheManager extends ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args) {}
}

class _AlwaysCacheManager extends ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args) {
    screen.addToCache(widget, args);
  }
}

class _OneCacheManager extends ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args) {
    screen.clearCache();
    screen.addToCache(widget, args);
  }
}

abstract class AbstractTheme {
  ThemeData data();
  ThemeMode mode();
}

class Application<S, T extends AbstractTheme> extends StatefulWidget with HistoryListener {
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
    required this.screens,
    Widget Function()? createHomeWidget,
    TransitionManager? transitionManager
  }):
    history = HistoryManager(HistoryState(screens.first, Arguments.empty)),
    _theme = initialTheme,
    this.createHomeWidget = createHomeWidget ?? (() => Home()),
    this.transitionManager = transitionManager ?? TransitionManager.standard {
      history.listen(this);
    }

  @override
  State createState() => ApplicationState();

  Future<void> push(Screen screen, {Arguments? args}) {
    return history.push(HistoryState(screen, args ?? Arguments.empty));
  }

  Future<void> replace(Screen screen, {Arguments? args}) {
    return history.replace(HistoryState(screen, args ?? Arguments.empty));
  }

  Future<bool> back() {
    return history.back();
  }

  Widget createTransition(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation) {
    return transitionManager.create(previous, current, direction, firstWidget, child, animation);
  }

  Duration getTransitionDuration(Screen? previous, Screen current, Direction? direction) {
    return transitionManager.duration(previous, current, direction);
  }

  @override
  void apply(HistoryAction action, HistoryState previous, HistoryState current) {
    instance.setState(() {});
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

abstract class TransitionManager {
  Widget create(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation);

  Duration duration(Screen? previous, Screen current, Direction? direction);

  static final TransitionManager standard = _StandardTransitionManager();
}

class _StandardTransitionManager extends TransitionManager {
  @override
  Widget create(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation) {
    if (direction != null && current.nav != null) {
      return createMoveTransition(direction, firstWidget, child, animation);
    } else {
      return FadeTransition(opacity: animation, child: child);
    }
    // return ScaleTransition(child: child, scale: animation);
  }

  @override
  Duration duration(Screen? previous, Screen current, Direction? direction) => Duration(milliseconds: 500);

  static Widget createMoveTransition(Direction direction, bool firstWidget, Widget child, Animation<double> animation) {
    double beginX = 1.0;
    if (direction == Direction.forward && firstWidget) {
      beginX = -1.0;
    } else if (direction == Direction.back && !firstWidget) {
      beginX = -1.0;
    }
    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(beginX, 0.0), end: Offset(0.0, 0.0)).animate(animation),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Application.instance.createMain()
    ),
    bottomNavigationBar: Application.instance.bottomNavBar()
  );
}

enum Direction {
  back,
  forward
}

class ApplicationState extends State<Application> {
  final List<Widget> children = [];

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: widget.title,
    navigatorKey: Application.navKey,
    theme: widget.theme.data(),
    debugShowCheckedModeBanner: false,
    home: WillPopScope(
      onWillPop: _willPop,
      child: widget.createHomeWidget()
    )
  );

  Future<bool> _willPop() async {
    return widget.back().then((success) => !success);
  }

  Screen? _previous;

  Widget createMain() {
    final Screen current = widget.screen;
    final Arguments currentArgs = widget.args;
    final Widget currentWidget = current.get(currentArgs);
    if (!children.contains(currentWidget)) {
      children.add(currentWidget);
    }
    final int index = children.indexOf(currentWidget);
    final Direction? direction = widget.direction(_previous, current);
    final Screen? previous = _previous;
    bool first = previous != current;
    if (previous != current) {    // Deactivate and Activate listeners for Screen
      final HistoryState? previousState = widget.history.previous;
      if (previousState != null) {
        final Widget? previousWidget = previousState.screen.cached(previousState.args);
        previousState.screen.invokeListeners(ScreenState.deactivated, previousWidget, previousState.args);
      }
      current.invokeListeners(ScreenState.activated, currentWidget, currentArgs);
    }

    _previous = current;
    final IndexedStack stack = IndexedStack(
      key: ValueKey<int>(index),
      index: index,
      children: children
    );
    return AnimatedSwitcher(
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Widget transition = widget.createTransition(previous, current, direction, first, child, animation);
        first = false;
        return transition;
      },
      duration: widget.getTransitionDuration(previous, current, direction),
      child: stack
    );
  }

  Widget? bottomNavBar() {
    final Screen screen = widget.screen;
    final Nav? nav = screen.getNav();
    if (nav == null) {
      return null;
    } else {
      final Screen navScreen = screen.getNavScreen()!;
      final NavBar bar = nav.bar;
      final List<Screen> screens = widget.screens.where((s) => s.hasNavBar(bar)).toList(growable: false);
      final List<BottomNavigationBarItem> items = screens.map((s) => BottomNavigationBarItem(
        icon: Icon(s.nav!.icon),
        label: s.nav!.label
      )).toList(growable: false);
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: screens.indexOf(navScreen),
        onTap: (index) => widget.push(screens[index]),
        items: items
      );
    }
  }
}