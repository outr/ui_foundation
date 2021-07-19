import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class TransitionManager {
  Widget create(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation);

  Duration duration(Screen? previous, Screen current, Direction? direction);

  static final TransitionManager standard = _StandardTransitionManager();
}

class _StandardTransitionManager extends TransitionManager {
  @override
  Widget create(Screen? previous, Screen current, Direction? direction, bool firstWidget, Widget child, Animation<double> animation) {
    if (direction != null && current.nav != null) {
      return createMoveTransition(direction, firstWidget, child, animation);
    } else {
      return FadeTransition(opacity: animation, child: child);
    }
    // return ScaleTransition(child: child, scale: animation);
  }

  @override
  Duration duration(Screen? previous, Screen current, Direction? direction) => Duration(milliseconds: 200);

  static Widget createMoveTransition(Direction direction, bool firstWidget, Widget child, Animation<double> animation) {
    double beginX = 1.0;
    if (direction == Direction.forward && firstWidget) {
      beginX = -1.0;
    } else if (direction == Direction.back && !firstWidget) {
      beginX = -1.0;
    }
    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(beginX, 0.0), end: Offset(0.0, 0.0)).animate(animation),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );
  }
}