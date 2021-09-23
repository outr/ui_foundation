import 'package:flutter/material.dart';

class Util {
  static Future<void> runLater(Function() f) {
    return Future.delayed(Duration.zero, f);
    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   f();
    // });
  }
}