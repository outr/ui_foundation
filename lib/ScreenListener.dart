import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class ScreenListener<V> {
  void apply(ScreenState state, ScreenStatus status, Widget? widget);
}