import 'package:flutter/material.dart';
import 'package:foundation_flutter/MapStack.dart';

import 'foundation.dart';

class ApplicationState extends State<Application> with HistoryListener {
  late final MapStack stack;

  @override
  void initState() {
    super.initState();

    stack = MapStack(this);

    ScreenState initial = widget.history.current;
    stack.add(initial, initial.screen.get(initial));
    initial.screen.manager.activating(this, initial);
    stack.active = initial;

    widget.history.listen(this);
  }

  @override
  void apply(HistoryAction action, ScreenState previous, ScreenState current) {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!stack.contains(current)) {
      stack.add(current, current.screen.get(current));
    }
    setState(() {
      current.screen.manager.activating(this, current);
      final Direction? direction =
          widget.direction(previous.screen, current.screen);
      bool first = previous.screen != current.screen;
      stack.activate(ActiveChange(previous, current, direction, first));
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: widget.title,
        navigatorKey: Application.navKey,
        theme: widget.theme.data(),
        debugShowCheckedModeBanner: false,
        home:
            WillPopScope(onWillPop: _willPop, child: widget.createHomeWidget()),
      );

  Future<bool> _willPop() async {
    return widget.back().then((success) => !success);
  }

  Widget createMain() {
    final ScreenState state = widget.history.current;
    final Widget currentWidget = state.screen.get(state);
    final ScreenState? previous = widget.history.previous;
    if (previous != state) {
      // Deactivate and Activate listeners for Screen
      if (previous != null) {
        previous.screen
          .invokeListeners(previous, ScreenStatus.deactivated, null);
      }
      state.screen
        .invokeListeners(state, ScreenStatus.activated, currentWidget);
    }

    return stack;
  }

  Widget? bottomNavBar() {
    final ScreenState state = widget.history.current;
    final Screen screen = state.screen;
    final Nav? nav = screen.getNav();
    if (nav == null) {
      return null;
    } else {
      final Screen navScreen = screen.getNavScreen()!;
      final NavBar bar = nav.bar;
      final List<Screen> screens =
          widget.screens.where((s) => s.hasNavBar(bar)).toList(growable: false);
      final List<BottomNavigationBarItem> items = screens
          .map((s) => BottomNavigationBarItem(
              label: s.nav!.label,
              icon: widget.createNavIcon(s.nav!)
          ))
          .toList(growable: false);
      BottomNavigationBar bottomBar = BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: screens.indexOf(navScreen),
          onTap: (index) => widget.push(screens[index].createState()),
          items: items);

      return bottomBar;
    }
  }
}
