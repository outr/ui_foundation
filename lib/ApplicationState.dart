import 'package:flutter/material.dart';
import 'package:foundation_flutter/MapStack.dart';

import 'foundation.dart';

class ApplicationState extends State<Application> with HistoryListener {
  final MapStack<ScreenState> stack = MapStack<ScreenState>();

  @override
  void initState() {
    super.initState();

    ScreenState initial = widget.history.current;
    stack.add(initial, initial.screen.get(initial));
    setState(() {
      initial.screen.manager.activating(this, initial);
      stack.active = initial;
    });

    widget.history.listen(this);
  }

  @override
  void apply(HistoryAction action, ScreenState previous, ScreenState current) {
    print('History: $action, previous: $previous, current: $current');
    if (!stack.contains(current)) {
      print('State doesn\'t already exist. Adding...');
      stack.add(current, current.screen.get(current));
    } else {
      print('State already added.');
    }
    setState(() {
      previous.screen.manager.deactivating(this, previous);
      current.screen.manager.activating(this, current);
      stack.active = current;
    });
  }

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

  Widget createMain() {
    final ScreenState state = widget.history.current;
    final Widget currentWidget = state.screen.get(state);
    final ScreenState? previous = widget.history.previous;
    final Direction? direction = widget.direction(previous?.screen, state.screen);
    bool first = previous?.screen != state.screen;
    if (previous != state) {    // Deactivate and Activate listeners for Screen
      if (previous != null) {
        previous.screen.invokeListeners(previous, ScreenStatus.deactivated, null);
      }
      state.screen.invokeListeners(state, ScreenStatus.activated, currentWidget);
    }

    // final IndexedStack stack = IndexedStack(
    //   key: ValueKey<String>('${current.name}:$currentArgs'),
    //   children: [],
    // )

    /*return AnimatedSwitcher(
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Widget transition = widget.createTransition(previous, current, direction, first, child, animation);
        first = false;
        return transition;
      },
      duration: widget.getTransitionDuration(previous, current, direction),
      child: Container(
        key: ValueKey<String>('${current.name}:$currentArgs'),
        child: child,
      )
    );*/

    // return child;

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
              icon: Icon(s.nav!.icon, size: 30), label: s.nav!.label))
          .toList(growable: false);
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: screens.indexOf(navScreen),
        onTap: (index) => widget.push(screens[index].createState()),
        items: items
      );
    }
  }
}