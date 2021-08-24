import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class ScreenListener<V> {
  void apply(Screen screen, ScreenState state, Widget? widget, V value);
}