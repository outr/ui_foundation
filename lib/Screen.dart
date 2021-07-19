import 'package:flutter/material.dart';

import 'foundation.dart';

class Screen {
  final String name;
  final Nav? nav;
  final Screen? parent;
  final Widget Function(Arguments) create;
  final bool includeSafeArea;

  final List<ScreenListener> _listeners = [];

  Screen({
    required this.name,
    required this.create,
    this.nav,
    this.parent,
    bool? includeSafeArea
  }):
    this.includeSafeArea = includeSafeArea ?? true;

  Widget get(Arguments args) => create(args);

  Nav? getNav() => nav ?? parent?.getNav();

  Screen? getNavScreen() {
    if (nav != null) {
      return this;
    } else {
      return parent?.getNavScreen();
    }
  }

  bool hasNavBar(NavBar bar) => nav?.bar == bar;

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
  String toString() => 'Screen($name)';
}