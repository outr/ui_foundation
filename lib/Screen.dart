import 'package:flutter/material.dart';

import 'foundation.dart';

class Screen {
  final String name;
  final Nav? nav;
  final Screen? parent;
  final bool includeSafeArea;
  final ScreenManager manager;
  final Widget Function(ScreenState) create;
  final void Function(HistoryAction) activated;
  final void Function(HistoryAction) deactivated;

  ScreenState? _state;
  Widget? _cached;

  final List<ScreenListener> _listeners = [];

  Screen({
    required this.name,
    required this.create,
    this.nav,
    this.parent,
    bool? includeSafeArea,
    ScreenManager? manager,
    void Function(HistoryAction)? activated,
    void Function(HistoryAction)? deactivated,
  }):
    this.includeSafeArea = includeSafeArea ?? true,
    this.manager = manager ?? ScreenManager.mostRecent,
    this.activated = activated ?? _defaultAction,
    this.deactivated = deactivated ?? _defaultAction;

  bool active = false;

  static void _defaultAction(HistoryAction action) {}

  ScreenState createState() => ScreenState(this);

  bool isDefaultState(ScreenState state) => true;

  Widget get(ScreenState state) {
    if (_state == state) {
      return _cached!;
    } else {
      Widget widget = create(state);
      if (includeSafeArea) {
        widget = SafeArea(child: widget);
      }
      widget = ScreenFocusWidget(this, widget);
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