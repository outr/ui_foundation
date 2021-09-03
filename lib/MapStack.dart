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
    print('Activating! $change');
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
      _keys.removeAt(index);
      return _widgets.removeAt(index);
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
      children: widget.children
    );

    ActiveChange? change = widget.change;
    print('Building with change: $change');
    bool first = change?.first ?? true;
    change?.first = false;
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

    // return AnimatedBuilder(
    //   animation: _animation,
    //   builder: (context, child) {
    //     return Opacity(
    //       opacity: _controller.value,
    //       child: Transform.scale(
    //         scale: 1.015 - (_controller.value * 0.015),
    //         child: child,
    //       ),
    //     );
    //   },
    //   child: IndexedStack(
    //     index: _index,
    //     children: widget.children,
    //   ),
    // );
  }
}

// class ActiveChange {
//   final ScreenState previous;
//   final ScreenState current;
//   final Direction? direction;
//   bool first;
//
//   ActiveChange(this.previous, this.current, this.direction, this.first);
//
//   @override
//   String toString() => "ActiveChange(previous: $previous, current: $current, direction: $direction, first: $first)";
// }
//
// class MapStack extends StatefulWidget {
//   final List<ScreenState> _keys = [];
//   final List<Widget> _widgets = [];
//
//   final ApplicationState appState;
//   final Application application;
//
//   ActiveChange? change;
//   ScreenState? _active;
//   MapStackState? _instance;
//
//   MapStack(this.appState):
//     application = appState.widget;
//
//   ScreenState get active => _active!;
//   set active(ScreenState state) {
//     _instance?.setState(() {
//       _active = state;
//     });
//   }
//
//   int get index {
//     int i = 0;
//     if (_active != null) {
//       i = _keys.indexOf(_active!);
//     }
//     return max(i, 0);
//   }
//
//   void activate(ActiveChange change) {
//     print('Activating! $change');
//     this.change = change;
//     active = change.current;
//   }
//
//   List<ScreenState> get keys => _keys.toList(growable: false);
//
//   bool contains(ScreenState state) => _keys.contains(state);
//
//   void add(ScreenState key, Widget widget) {
//     if (_instance != null) {
//       // Util.runLater(() {
//         _instance!.setState(() {
//           _add(key, widget);
//         });
//       // });
//     } else {
//       _add(key, widget);
//     }
//     if (_active == null) {
//       active = key;
//     }
//   }
//
//   void remove(ScreenState key) {
//     print('About to remove $key');
//     if (_keys.contains(key)) {
//       Util.runLater(() {
//         _instance!.setState(() {
//           int index = _keys.indexOf(key);
//           if (index != -1) {
//             _keys.remove(key);
//             _widgets.removeAt(index);
//           }
//         });
//         /*print('*** Removing $key');
//       int index = _keys.indexOf(key);
//       if (index != -1) {
//         _keys.remove(key);
//         print('Current Index: ${_instance!.index}, Removing: $index');
//         if (_instance!.index >= index) {
//           _instance?.index = max(_instance!.index - 1, 0);
//           print('Updating index to ${index - 1}!');
//         }
//         if (_active == key) {
//           active = _keys[0];
//         }
//         print('Removing at $index...');
//         _widgets.removeAt(index);
//         print('Removed!');
//       }*/
//       });
//     }
//   }
//
//   void _add(ScreenState key, Widget widget) {
//     _keys.add(key);
//     _widgets.add(widget);
//   }
//
//   @override
//   State createState() => MapStackState();
// }
//
// class MapStackState extends State<MapStack> with TickerProviderStateMixin {
//   @override
//   void initState() {
//     super.initState();
//
//     widget._instance = this;
//   }
//
//   @override
//   Widget build(BuildContext context) => AnimatedIndexedStack(
//       stack: widget,
//       children: widget._widgets
//   );
// }
//
// // TODO: Remove AnimatedIndexedStack in favor of Stack so we don't have to animate one widget off-screen before animating the one on
// class AnimatedIndexedStack extends StatefulWidget {
//   final MapStack stack;
//   final List<Widget> children;
//
//   const AnimatedIndexedStack({
//     required this.stack,
//     required this.children,
//   });
//
//   @override
//   _AnimatedIndexedStackState createState() => _AnimatedIndexedStackState();
// }
//
// class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 200),
//     );
//     _animation = Tween(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.ease,
//       ),
//     );
//
//     _controller.forward();
//     super.initState();
//   }
//
//   int _lastIndex = 0;
//
//   @override
//   void didUpdateWidget(AnimatedIndexedStack oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     int index = widget.stack.index;
//     if (index != _lastIndex) {
//       _controller.reverse().then((_) {
//         Util.runLater(() {
//           print('Updating index!');
//           setState(() => _lastIndex = index);
//           _controller.forward();
//         });
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print('MapStack build!');
//     IndexedStack stack = IndexedStack(
//       index: widget.stack.index,
//       children: widget.children,
//     );
//     ActiveChange? change = widget.stack.change;
//     bool first = change?.first ?? true;
//     change?.first = false;
//     Widget transition = widget.stack.application.createTransition(
//         change?.previous.screen,
//         change?.current.screen ?? widget.stack.application.history.current.screen,
//         change?.direction,
//         first,
//         stack,
//         _animation
//     );
//     if (!first) {
//       // Deactivate the previous screen
//       print('Deactivating $change');
//       change?.previous.screen.manager.deactivating(widget.stack.appState, change.previous);
//       widget.stack.change = null;
//     }
//     return transition;
//   }
// }