import 'dart:collection';

import 'package:flutter/material.dart';

// TODO: Support customized animations
class MapStack<T> extends StatefulWidget {
  final List<T> _keys = [];
  final List<Widget> _widgets = [];

  T? _active;
  MapStackState? _instance;

  T get active => _active!;
  set active(T t) {
    _instance?.index = _keys.indexOf(t);
  }

  Iterable<T> get keys => _keys;

  bool contains(T t) => _keys.contains(t);

  void add(T key, Widget widget) {
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

  Widget? remove(T key) {
    if (_instance != null) {
      Widget? w;
      _instance!.setState(() {
        w = _remove(key);
      });
      return w;
    } else {
      return _remove(key);
    }
  }

  void _add(T key, Widget widget) {
    _keys.add(key);
    _widgets.add(widget);
  }

  Widget? _remove(T key) {
    int index = _keys.indexOf(key);
    if (index != -1) {
      _keys.remove(key);
      return _widgets.removeAt(index);
    }
    // TODO: deal with removal of active
    return null;
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
      index: _index,
      children: widget._widgets
  );
}

class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AnimatedIndexedStack({
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
      duration: Duration(milliseconds: 450),
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FadeTransition(
            opacity: _animation,
            child: child
        );
      },
      child: IndexedStack(
        index: _index,
        children: widget.children,
      ),
    );
  }
}