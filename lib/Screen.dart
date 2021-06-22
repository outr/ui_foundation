import 'package:flutter/material.dart';

import 'foundation.dart';

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