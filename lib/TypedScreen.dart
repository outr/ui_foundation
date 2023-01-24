import 'package:flutter/material.dart';

import 'foundation.dart';

class TypedScreen<V> extends Screen {
  final V Function() defaultValue;
  final Widget Function(TypedScreenState<V>) createTyped;

  TypedScreen({
    required String name,
    required this.defaultValue,
    required this.createTyped,
    Nav? nav,
    Screen? parent,
    bool? includeSafeArea,
    ScreenManager? manager,
    void Function(HistoryAction)? activated,
    void Function(HistoryAction)? deactivated,
  }):
        super(name: name,
          create: (state) => createTyped(state as TypedScreenState<V>),
          nav: nav,
          parent: parent,
          includeSafeArea: includeSafeArea,
          manager: manager,
          activated: activated,
          deactivated: deactivated
      );

  @override
  ScreenState createState() => createTypedState(defaultValue());

  @override
  bool isDefaultState(ScreenState state) {
    if (state is TypedScreenState && state.value == defaultValue()) {
      return true;
    } else {
      return false;
    }
  }

  ScreenState createTypedState(V value) => TypedScreenState<V>(this, value);
}