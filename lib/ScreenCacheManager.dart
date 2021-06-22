import 'package:flutter/material.dart';

import 'foundation.dart';

abstract class ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args);

  static final ScreenCacheManager never = _NeverCacheManager();
  static final ScreenCacheManager always = _AlwaysCacheManager();
  static final ScreenCacheManager one = _OneCacheManager();
}

class _NeverCacheManager extends ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args) {}
}

class _AlwaysCacheManager extends ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args) {
    screen.addToCache(widget, args);
  }
}

class _OneCacheManager extends ScreenCacheManager {
  void cache(Screen screen, Widget widget, Arguments args) {
    screen.clearCache();
    screen.addToCache(widget, args);
  }
}