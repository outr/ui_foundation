import 'package:flutter/material.dart';

import 'foundation.dart';

class ApplicationState extends State<Application> {
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: widget.title,
      navigatorKey: Application.navKey,
      theme: widget.theme.data(),
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
          onWillPop: _willPop,
          child: widget.createHomeWidget()
      )
  );

  Future<bool> _willPop() async {
    return widget.back().then((success) => !success);
  }

  Screen? _previous;

  Widget createMain() {
    final Screen current = widget.screen;
    final Arguments currentArgs = widget.args;
    final Widget currentWidget = current.get(currentArgs);
    final Direction? direction = widget.direction(_previous, current);
    final Screen? previous = _previous;
    bool first = previous != current;
    if (previous != current) {    // Deactivate and Activate listeners for Screen
      final HistoryState? previousState = widget.history.previous;
      if (previousState != null) {
        previousState.screen.invokeListeners(ScreenState.deactivated, null, previousState.args);
      }
      current.invokeListeners(ScreenState.activated, currentWidget, currentArgs);
    }

    _previous = current;

    return AnimatedSwitcher(
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Widget transition = widget.createTransition(previous, current, direction, first, child, animation);
        first = false;
        return transition;
      },
      duration: widget.getTransitionDuration(previous, current, direction),
      child: Container(
        key: ValueKey<String>('${current.name}:$currentArgs'),
        child: currentWidget,
      )
    );
  }

  Widget? bottomNavBar() {
    final Screen screen = widget.screen;
    final Nav? nav = screen.getNav();
    if (nav == null) {
      return null;
    } else {
      final Screen navScreen = screen.getNavScreen()!;
      final NavBar bar = nav.bar;
      final List<Screen> screens = widget.screens.where((s) => s.hasNavBar(bar)).toList(growable: false);
      final List<BottomNavigationBarItem> items = screens.map((s) => BottomNavigationBarItem(
        icon: Icon(s.nav!.icon),
        label: s.nav!.label
      )).toList(growable: false);
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: screens.indexOf(navScreen),
        onTap: (index) => widget.push(screens[index]),
        items: items
      );
    }
  }
}