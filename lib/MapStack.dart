import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'foundation.dart';

class ActiveChange {
  final ScreenState previous;
  final ScreenState current;
  final Direction? direction;
  bool first;

  ActiveChange(this.previous, this.current, this.direction, this.first);

  @override
  String toString() => "ActiveChange(previous: $previous, current: $current, direction: $direction, first: $first)";
}

class MapStack extends StatefulWidget {
  final List<ScreenState> _keys = [];
  final List<Widget> _widgets = [];

  final ApplicationState appState;
  final Application application;

  ActiveChange? change;
  ScreenState? _active;
  MapStackState? _instance;

  MapStack(this.appState):
    application = appState.widget;

  ScreenState get active => _active!;
  set active(ScreenState state) {
    _instance?.index = _keys.indexOf(state);
  }

  void activate(ActiveChange change) {
    this.change = change;
    active = change.current;
  }

  List<ScreenState> get keys => _keys.toList(growable: false);

  bool contains(ScreenState state) => _keys.contains(state);

  void add(ScreenState key, Widget widget) {
    if (_instance != null) {
      _instance!.setState(() {
        _add(key, widget);
      });
    } else {
      _add(key, widget);
    }
    if (_active == null) {
      active = key;
    }
  }

  void remove(ScreenState key) {
    if (_instance != null) {
      _remove(key);
    } else {
      _remove(key);
    }
  }

  void _add(ScreenState key, Widget widget) {
    _keys.add(key);
    _widgets.add(widget);
  }

  void _remove(ScreenState key) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      int index = _keys.indexOf(key);
      if (index != -1) {
        _keys.remove(key);
        if (_active == key) {
          if (index > 0) {
            index--;
            _instance?.index = index;
          }
          active = _keys[0];
        }
        _widgets.removeAt(index);
      }
    });
  }

  @override
  State createState() => MapStackState();
}

class MapStackState extends State<MapStack> with TickerProviderStateMixin {
  int _index = 0;

  int get index => _index;
  set index(int i) {
    setState(() {
      _index = i;
    });
  }

  @override
  void initState() {
    super.initState();

    widget._instance = this;
  }

  @override
  Widget build(BuildContext context) => AnimatedIndexedStack(
      stack: widget,
      index: _index,
      children: widget._widgets
  );
}

// TODO: Remove AnimatedIndexedStack in favor of Stack so we don't have to animate one widget off-screen before animating the one on
class AnimatedIndexedStack extends StatefulWidget {
  final MapStack stack;
  final int index;
  final List<Widget> children;

  const AnimatedIndexedStack({
    required this.stack,
    required this.index,
    required this.children,
  });

  @override
  _AnimatedIndexedStackState createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _index;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
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
      children: widget.children,
    );
    ActiveChange? change = widget.stack.change;
    bool first = change?.first ?? true;
    change?.first = false;
    Widget transition = widget.stack.application.createTransition(
        change?.previous.screen,
        change?.current.screen ?? widget.stack.application.history.current.screen,
        change?.direction,
        first,
        stack,
        _animation
    );
    if (!first) {
      // Deactivate the previous screen
      change?.previous.screen.manager.deactivating(widget.stack.appState, change.previous);
    }
    return transition;
  }
}