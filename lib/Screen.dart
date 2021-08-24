import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class Screen<V> {
  final String name;
  final V defaultValue;
  final Nav? nav;
  final Screen? parent;
  final bool includeSafeArea;

  Widget? _cached;
  V? _value;

  final List<ScreenListener> _listeners = [];

  Screen({
    required this.name,
    required this.defaultValue,
    this.nav,
    this.parent,
    bool? includeSafeArea
  }):
    this.includeSafeArea = includeSafeArea ?? true;

  Widget create(covariant V value);

  Widget get(covariant V value) {
    if (_cached != null && _value == value) {
      return _cached!;
    } else {
      Widget widget = create(value);
      if (includeSafeArea) {
        widget = new SafeArea(child: widget);
      }
      _cached = widget;
      _value = value;
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

  void invokeListeners(ScreenState state, Widget? widget, V value) {
    _listeners.forEach((listener) => listener.apply(this, state, widget, value));
  }

  @override
  String toString() => 'Screen($name)';
}