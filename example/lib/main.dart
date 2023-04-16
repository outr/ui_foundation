import 'package:flutter/material.dart';
import 'package:ui_foundation/foundation.dart';

final NavBar navBar = NavBar();

final Nav screen1Nav = Nav('Page 1', Icons.account_circle, navBar);

class PageThreeData {
  final String message;

  PageThreeData(this.message);
}

final Screen screen0 = Screen(
  name: "Begin",
  create: (state) => ElevatedButton(
    onPressed: () => application.pushScreen(screen1),
    child: Text('Begin'),
  ),
  // manager: ScreenManager.onlyActive
);

final Screen screen1 = Screen(
  name: "Page 1",
  includeSafeArea: false,
  nav: screen1Nav,
  create: (state) => PageOne(),
);
final Screen screen2 = Screen(
  name: "Page 2",
  nav: Nav('Page 2', Icons.settings, navBar),
  create: (state) => PageTwo(),
);
final TypedScreen<PageThreeData> screen3 = TypedScreen(
  name: "Page 3",
  defaultValue: () => PageThreeData('Default!'),
  nav: Nav('Page 3', Icons.nature, navBar),
  createTyped: (state) => PageThree(data: state.value),
);
final Screen details = Screen(
  name: "Details",
  parent: screen2,
  create: (state) => DetailsPage(),
);

final Application<AppState, MyTheme> application = Application(
  state: AppState(),
  title: 'My Application Test',
  initialTheme: MyTheme.light,
  screens: [screen0, screen1, screen2, details, screen3],
);

void main() {
  runApp(application);
}

class AppState {}

class PageOne extends StatefulWidget {
  @override
  State createState() => PageOneState();
}

class PageOneState extends State<PageOne>
    with AutomaticKeepAliveClientMixin<PageOne> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    print("***** REBUILDING PAGE 1");
    return Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            Padding(
                child: Text('Count: $_counter',
                    style: Theme.of(context).textTheme.headline4),
                padding: EdgeInsets.only(top: 20.0)),
            ElevatedButton(onPressed: increment, child: Text("Increment")),
            ElevatedButton(
                onPressed: () => application.pushScreen(screen0),
                child: Text('Go to Begin'))
          ],
        ));
  }

  void increment() => setState(() {
    _counter++;
    application.setNavBadge(screen1Nav, _counter);
  });

  @override
  bool get wantKeepAlive => true;
}

class PageTwo extends StatelessWidget {
  const PageTwo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(children: [
          ElevatedButton(
            onPressed: () => application.pushScreen(details),
            child: Text('Don\'t Click me'),
            style: application.theme.specialButton,
          ),
          ElevatedButton(
            onPressed: () => application
                .push(screen3.createTypedState(PageThreeData('Hello, World!'))),
            child: Text('Go to Page 3'),
          ),
          ElevatedButton(
            onPressed: () => application.theme = MyTheme.dark,
            child: Text('Change Theme'),
          ),
        ]));
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('jk, i\'m not evil, you can click me'),
          ElevatedButton(
            onPressed: () => application.back(),
            child: Text('Click me!'),
          ),
        ]),
      ),
    );
  }
}

class PageThree extends StatelessWidget {
  final PageThreeData data;

  const PageThree({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text('Three: ${data.message}'),
    );
  }
}

class MyTheme extends AbstractTheme {
  final Color bg1;
  final Color accent1;
  final bool isDark;
  final ButtonStyle specialButton;

  MyTheme({required this.bg1, required this.accent1, required this.isDark})
      : specialButton = ButtonStyle(
            foregroundColor: MaterialStateProperty.all(accent1),
            backgroundColor: MaterialStateProperty.all(bg1));

  @override
  ThemeData data() {
    final TextTheme text =
        (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
    final Color textColor = text.bodyText1?.color ?? Colors.white;
    final ColorScheme color = ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent1,
        primaryVariant: accent1,
        secondary: accent1,
        secondaryVariant: accent1,
        background: bg1,
        surface: bg1,
        onBackground: textColor,
        onSurface: textColor,
        onError: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: Colors.red.shade400);
    // return ThemeData.from(textTheme: text, colorScheme: color)
    //   .copyWith(buttonColor: accent1, cursorColor: accent1, toggleableActiveColor: accent1);
    final ThemeData td = ThemeData(primaryColor: accent1, colorScheme: color);
    return td;
  }

  @override
  ThemeMode mode() => isDark ? ThemeMode.dark : ThemeMode.light;

  static final MyTheme light =
      new MyTheme(bg1: Colors.white, accent1: Colors.blueAccent, isDark: false);
  static final MyTheme dark = new MyTheme(
      bg1: Colors.black26, accent1: Colors.greenAccent, isDark: false);
}
