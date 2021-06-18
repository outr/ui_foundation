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
  final Nav? nav;
  final Screen? parent;
  final Widget Function(Arguments) create;
  final ScreenCacheManager? cacheManager;

  final Map<Arguments, Widget> _cacheMap = {};
  final List<ScreenListener> _listeners = [];

  Screen({
    required this.create,
    this.nav,
    this.parent,
    this.cacheManager
  }) {
    listen(this);
  }

  Widget get(Arguments args) {
    final Widget? cached = _cacheMap[args];
    if (cached != null) {
      _invokeListeners(ScreenState.active, cached, args);
      return cached;
    } else {
      final Widget w = create(args);
      _invokeListeners(ScreenState.create, w, args);
      _invokeListeners(ScreenState.active, w, args);
      cacheManager?.cache(this, w, args);
      return w;
    }
  }

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
      _invokeListeners(ScreenState.dispose, existing, args);
    }
  }

  void removeFromCache(Widget widget, Arguments args) {
    final Widget? removed = _cacheMap.remove(args);
    if (removed != null) {
      _invokeListeners(ScreenState.dispose, removed, args);
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

  void _invokeListeners(ScreenState state, Widget widget, Arguments args) {
    _listeners.forEach((listener) => listener.apply(this, state, widget, args));
  }

  @override
  void apply(Screen screen, ScreenState state, Widget widget, Arguments args) {
    if (state == ScreenState.dispose) {
      Application.instance.children.remove(widget);
    }
  }
}

abstract class ScreenListener {
  void apply(Screen screen, ScreenState state, Widget widget, Arguments args);
}

enum ScreenState {
  create,
  active,
  dispose
}

class HistoryManager {
  final List<HistoryState> _entries;
  final List<HistoryListener> _listeners = [];

  HistoryManager(HistoryState initialState):
    _entries = [initialState];

  bool get isTop => _entries.length == 1;

  HistoryState get current => _entries.last;

  // TODO: Use animatedswitcher to switch between

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

class Application<T extends AbstractTheme> extends StatefulWidget with HistoryListener {
  final String title;
  final Widget Function() createHomeWidget;

  final List<Screen> screens;
  final HistoryManager history;

  T _theme;

  Screen get screen => history.current.screen;
  Arguments get args => history.current.args;

  T get theme => _theme;
  set theme(T theme) {
    _theme = theme;
    instance.setState(() {});
  }

  static ApplicationState get instance => of(staticContext!)!;

  // TODO: tabTransition and internalTransition

  Application({
    required this.title,
    required T initialTheme,
    required this.screens,
    Widget Function()? createHomeWidget,
  }):
    history = HistoryManager(HistoryState(screens.first, Arguments.empty)),
    _theme = initialTheme,
    this.createHomeWidget = createHomeWidget ?? (() => Home()){
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

  @override
  void apply(HistoryAction action, HistoryState previous, HistoryState current) {
    instance.setState(() {});
  }

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static BuildContext? get staticContext => navKey.currentContext;

  static ApplicationState? of(BuildContext context, {bool root = false}) => root
      ? context.findRootAncestorStateOfType<ApplicationState>()
      : context.findAncestorStateOfType<ApplicationState>();
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

  Widget createMain() {
    final Widget current = widget.screen.get(widget.args);
    if (!children.contains(current)) {
      children.add(current);
    }
    final int index = children.indexOf(current);
    final IndexedStack stack = IndexedStack(
      key: ValueKey<int>(index),
      index: index,
      children: children
    );
    return AnimatedSwitcher(
      transitionBuilder: (Widget child, Animation<double> animation) {
        final inAnimation = Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
            .animate(animation);
        final outAnimation = Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0))
            .animate(animation);
        if (child.key == stack.key) {
          return ClipRect(
            child: SlideTransition(
              position: inAnimation,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: child,
              ),
            ),
          );
        } else {
          return ClipRect(
            child: SlideTransition(
              position: outAnimation,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: child,
              ),
            ),
          );
        }
      },
      duration: const Duration(milliseconds: 500),
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