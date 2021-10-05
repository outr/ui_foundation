import 'package:flutter/material.dart';

import 'foundation.dart';

class ScreenFocusWidget extends StatelessWidget {
  final Screen screen;
  final Widget widget;

  ScreenFocusWidget(this.screen, this.widget);

  @override
  Widget build(BuildContext context) => ExcludeFocus(
      excluding: !screen.active,
      child: widget
  );
}