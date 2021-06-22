import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class ScreenListener {
  void apply(Screen screen, ScreenState state, Widget? widget, Arguments args);
}