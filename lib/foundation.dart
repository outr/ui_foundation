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

class Screen {
  final Nav? nav;
  final Screen? parent;
  final Widget Function(Arguments) create;
  final ScreenCacheManager? cacheManager;

  final Map<Arguments, Widget> _cacheMap = {};

  Screen({
    required this.create,
    this.nav,
    this.parent,
    this.cacheManager
  });

  Widget get(Arguments args) {
    final Widget? cached = _cacheMap[args];
    if (cached != null) {
      return cached;
    } else {
      final Widget w = create(args);
      cacheManager?.cache(args, w, _cacheMap);
      return w;
    }
  }

  // TODO: ScreenState and listeners for init, active, inactive, dispose
  // TODO: remove from IndexedStack (ApplicationState.children) for each item removed from cache

  Nav? getNav() => nav ?? parent?.getNav();

  bool hasNavBar(NavBar bar) => nav?.bar == bar;

  void clearCache() => _cacheMap.clear();
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
  void cache(Arguments args, Widget widget, Map<Arguments, Widget> cacheMap);

  static final ScreenCacheManager never = _NeverCacheManager();
  static final ScreenCacheManager always = _AlwaysCacheManager();
  static final ScreenCacheManager one = _OneCacheManager();
}

class _NeverCacheManager extends ScreenCacheManager {
  void cache(Arguments args, Widget widget, Map<Arguments, Widget> cacheMap) {}
}

class _AlwaysCacheManager extends ScreenCacheManager {
  void cache(Arguments args, Widget widget, Map<Arguments, Widget> cacheMap) {
    cacheMap[args] = widget;
  }
}

class _OneCacheManager extends ScreenCacheManager {
  void cache(Arguments args, Widget widget, Map<Arguments, Widget> cacheMap) {
    cacheMap.clear();
    cacheMap[args] = widget;
  }
}

abstract class AbstractTheme {
  ThemeData data();
  ThemeMode mode();
}

class Application<T extends AbstractTheme> extends StatefulWidget with HistoryListener {
  final String title;
  T _theme;
  final List<Screen> screens;

  final HistoryManager history;

  Screen get screen => history.current.screen;

  T get theme => _theme;
  void set theme(T theme) {
    _theme = theme;
    instance.setState(() {});
  }

  ApplicationState get instance => of(staticContext!)!;

  Application({
    required this.title,
    required T initialTheme,
    required this.screens
  }):
    history = HistoryManager(HistoryState(screens.first, Arguments.empty)),
    _theme = initialTheme {
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
      child: Scaffold(
        body: SafeArea(
          child: _createStack()
        ),
        bottomNavigationBar: _buildNavBar(),
      )
    )
  );

  Future<bool> _willPop() async {
    return widget.back().then((success) => !success);
  }

  IndexedStack _createStack() {
    final Widget current = widget.screen.get(Arguments.empty);
    if (!children.contains(current)) {
      children.add(current);
    }
    final int index = children.indexOf(current);
    return IndexedStack(
      index: index,
      children: children
    );
  }

  Widget? _buildNavBar() {
    final Screen screen = widget.screen;
    final Nav? nav = screen.getNav();
    if (nav == null) {
      return null;
    } else {
      final NavBar bar = nav.bar;
      final List<Screen> screens = widget.screens.where((s) => s.hasNavBar(bar)).toList(growable: false);
      final List<BottomNavigationBarItem> items = screens.map((s) => BottomNavigationBarItem(
        icon: Icon(s.nav!.icon),
        label: s.nav!.label
      )).toList(growable: false);
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: screens.indexOf(screen),
        onTap: (index) => widget.push(screens[index]),
        items: items
      );
    }
  }
}