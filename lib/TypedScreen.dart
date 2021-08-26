import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class TypedScreen<V> extends Screen {
  final V defaultValue;

  TypedScreen({
    required String name,
    required this.defaultValue,
    Nav? nav,
    Screen? parent,
    bool? includeSafeArea
  }):
        super(name: name, nav: nav, parent: parent, includeSafeArea: includeSafeArea);

  @override
  ScreenState createState() => createTypedState(defaultValue);

  ScreenState createTypedState(V value) => TypedScreenState<V>(this, value);

  @override
  Widget create(ScreenState state) => createTyped(state as TypedScreenState<V>);

  Widget createTyped(TypedScreenState<V> state);
}