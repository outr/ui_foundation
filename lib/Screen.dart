import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class Screen {
  final String name;
  final Nav? nav;
  final Screen? parent;
  final bool includeSafeArea;
  final ScreenManager manager;

  ScreenState? _state;
  Widget? _cached;

  final List<ScreenListener> _listeners = [];

  Screen({
    required this.name,
    this.nav,
    this.parent,
    bool? includeSafeArea,
    ScreenManager? manager
  }):
    this.includeSafeArea = includeSafeArea ?? true,
    this.manager = manager ?? ScreenManager.mostRecent;

  ScreenState createState() => ScreenState(this);

  bool isDefaultState(ScreenState state) => true;

  Widget create(ScreenState state);

  Widget get(ScreenState state) {
    if (_state == state) {
      return _cached!;
    } else {
      Widget widget = create(state);
      if (includeSafeArea) {
        widget = new SafeArea(child: widget);
      }
      _cached = widget;
      _state = state;
      return widget;
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

  void listen(ScreenListener listener) {
    _listeners.add(listener);
  }

  void remove(ScreenListener listener) {
    _listeners.remove(listener);
  }

  void invokeListeners(ScreenState state, ScreenStatus status, Widget? widget) {
    _listeners.forEach((listener) => listener.apply(state, status, widget));
  }

  @override
  String toString() => 'Screen($name)';
}