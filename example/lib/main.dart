import 'package:flutter/material.dart';

import 'package:foundation_flutter/foundation.dart';

final NavBar navBar = NavBar();

final Screen screen0 = Screen(name: 'Begin', create: (args) {
  return ElevatedButton(
    onPressed: () => application.push(screen1),
    child: Text('Begin'),
  );
});

final Screen screen1 = Screen(name: 'Page 1', includeSafeArea: false, nav: Nav('Page 1', Icons.account_circle, navBar), create: (args) {
  return PageOne();
});

final Screen screen2 = Screen(name: 'Page 2', nav: Nav('Page 2', Icons.settings, navBar), create: (args) {
  return PageTwo();
});

final Screen screen3 = Screen(name: 'Page 3', nav: Nav('Page 3', Icons.nature, navBar), create: (args) {
  return PageThree(args: args);
});

final Screen details = Screen(name: 'Details', parent: screen2, create: (params) {
  return DetailsPage();
});

final Application<AppState, MyTheme> application = Application<AppState, MyTheme>(
  state: AppState(),
  title: 'My Application Test',
  initialTheme: MyTheme.light,
  screens: [screen0, screen1, screen2, details, screen3]
);

void main() {
  runApp(application);
}

class AppState {
  int _counter = 0;
}

class PageOne extends StatefulWidget {
  @override
  State createState() {
    return PageOneState();
  }
}

class PageOneState extends State<PageOne> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          Text('Count: ${application.state._counter}'),
          ElevatedButton(onPressed: increment, child: Text("Increment"))
        ],
      )
    );
  }

  void increment() => setState(() {
    application.state._counter++;
  });
}

class PageTwo extends StatelessWidget {
  const PageTwo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
            children: [
              ElevatedButton(
                onPressed: () => application.push(details),
                child: Text('Don\'t Click me'),
                style: application.theme.specialButton,
              ),
              ElevatedButton(
                onPressed: () => application.push(screen3, args: Arguments({'test': 'Hello, World'})),
                child: Text('Go to Page 3'),
              ),
              ElevatedButton(
                onPressed: () => application.theme = MyTheme.dark,
                child: Text('Change Theme'),
              ),
            ]
        )
    );
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('jk, i\'m not evil, you can click me'),
              ElevatedButton(
                onPressed: () => application.back(),
                child: Text('Click me!'),
              ),
            ]
        ),
      ),
    );
  }
}

class PageThree extends StatelessWidget {
  final Arguments args;

  const PageThree({Key? key, required this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text('Three: $args'),
    );
  }
}

class MyTheme extends AbstractTheme {
  final Color bg1;
  final Color accent1;
  final bool isDark;
  final ButtonStyle specialButton;

  MyTheme({required this.bg1, required this.accent1, required this.isDark}):
    specialButton = ButtonStyle(foregroundColor: MaterialStateProperty.all(accent1), backgroundColor: MaterialStateProperty.all(bg1));

  @override
  ThemeData data() {
    final TextTheme text = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
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
        error: Colors.red.shade400
    );
    // return ThemeData.from(textTheme: text, colorScheme: color)
    //   .copyWith(buttonColor: accent1, cursorColor: accent1, toggleableActiveColor: accent1);
    final ThemeData td = ThemeData(
        primaryColor: accent1,
        colorScheme: color
    );
    return td;
  }

  @override
  ThemeMode mode() => isDark ? ThemeMode.dark : ThemeMode.light;

  static final MyTheme light = new MyTheme(bg1: Colors.white, accent1: Colors.blueAccent, isDark: false);
  static final MyTheme dark = new MyTheme(bg1: Colors.black26, accent1: Colors.greenAccent, isDark: false);
}