import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'foundation.dart';

class ActiveChange {
  final ScreenState? previous;
  final ScreenState current;
  final Direction? direction;
  bool first;

  ActiveChange(this.previous, this.current, this.direction, this.first);

  @override
  String toString() => "ActiveChange(previous: $previous, current: $current, direction: $direction, first: $first)";
}

class MapStack extends StatefulWidget {
  final ApplicationState appState;
  final Application application;
  final List<ScreenState> _keys = [];
  final List<Widget> _widgets = [];

  ActiveChange? change;
  ScreenState? _active;
  MapStackState? _instance;

  MapStack(this.appState):
    application = appState.widget;

  List<ScreenState> get keys => _keys.toList(growable: false);

  ScreenState get active => _keys[index];
  set active(ScreenState state) {
    if (!contains(state)) {
      add(state, state.screen.get(state));
    }
    _active = state;
    _instance?.setState(() {
    });
  }

  int get index {
    if (_active != null) {
      return max(_keys.indexOf(_active!), 0);
    } else {
      return 0;
    }
  }

  void activate(ActiveChange change) {
    this.change = change;
    active = change.current;
  }

  void add(ScreenState key, Widget widget) {
    if (!contains(key)) {
      _keys.add(key);
      _widgets.add(widget);
    }
  }

  Widget? remove(ScreenState key) {
    int index = _keys.indexOf(key);
    if (index != -1) {
      // _keys.removeAt(index);
      // return _widgets.removeAt(index);

      // Stub instead of remove to avoid
      _keys[index] = ScreenState.stub;
      Widget removed = _widgets[index];
      _widgets[index] = SizedBox.shrink();
      return removed;
    } else {
      return null;
    }
  }

  bool contains(ScreenState key) => _keys.contains(key);

  @override
  State createState() => MapStackState();
}

class MapStackState extends State<MapStack> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    widget._instance = this;
  }

  @override
  Widget build(BuildContext context) => AnimatedIndexedStack(
    stack: widget,
    change: widget.change,
    index: widget.index,
    children: widget._widgets.toList(growable: false)
  );
}

class AnimatedIndexedStack extends StatefulWidget {
  final MapStack stack;
  final ActiveChange? change;
  final int index;
  final List<Widget> children;

  const AnimatedIndexedStack({
    Key? key,
    required this.stack,
    required this.change,
    required this.index,
    required this.children,
  }) : super(key: key);

  @override
  _AnimatedIndexedStackState createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _index = 0;

  @override
  void initState() {
    ActiveChange? change = widget.change;
    _controller = AnimationController(
      vsync: this,
      duration: widget.stack.application.getTransitionDuration(
        change?.previous?.screen,
        change?.current.screen ?? widget.stack.application.history.current.screen,
        change?.direction
      ),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.ease,
      ),
    );

    _index = widget.index;
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _index) {
      _controller.reverse().then((_) {
        setState(() => _index = widget.index);
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IndexedStack stack = IndexedStack(
      index: _index,
      children: widget.children
    );

    ActiveChange? change = widget.change;
    bool first = change?.first ?? true;
    change?.first = false;
    // TODO: support changing duration based on the transition
    // _controller.duration = widget.stack.application.getTransitionDuration(
    //     change?.previous?.screen,
    //     change?.current.screen ?? widget.stack.application.history.current.screen,
    //     change?.direction
    // );
    Widget transition = widget.stack.application.createTransition(
      change?.previous?.screen,
      change?.current.screen ?? widget.stack.application.history.current.screen,
      change?.direction,
      first,
      stack,
      _animation
    );
    if (!first) {
      // Deactivate the previous screen
      change?.previous?.screen.manager.deactivating(widget.stack.appState, change.previous!);
    }
    return transition;
  }
}