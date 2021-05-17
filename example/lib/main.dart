import 'package:flutter/material.dart';

import 'package:foundation_flutter/foundation_flutter.dart';

final Screen screen0 = Screen(key: '0', createWidget: (args) {
  return ElevatedButton(
    onPressed: () => application.push(screen1),
    child: Text('Begin'),
  );
});

final Screen screen1 = Screen(key: '1', nav: Nav('Page 1', Icons.account_circle), createWidget: (args) {
  return PageOne();
});

final Screen screen2 = Screen(key: '2', nav: Nav('Page 2', Icons.settings), createWidget: (args) {
  return PageTwo();
});

final Screen screen3 = Screen(key: '3', nav: Nav('Page 3', Icons.nature), createWidget: (args) {
  return PageThree(args: args);
});

final Screen details = Screen(key: 'details', parent: screen2, createWidget: (params) {
  return DetailsPage();
});

final Application application = Application(
    title: 'My Application Test',
    theme: ThemeData(primarySwatch: Colors.blue),
    screens: [screen0, screen1, screen2, details, screen3]
);

void main() {
  runApp(application);
}

class PageOne extends StatelessWidget {
  const PageOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text('One'),
    );
  }
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
              ),
              ElevatedButton(
                onPressed: () => application.push(screen3, args: {'test': 'Hello, World'}),
                child: Text('Go to Page 3'),
              ),
              ElevatedButton(
                onPressed: () => application.changeTheme(context, ThemeData(primarySwatch: Colors.red)),
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
                onPressed: () => Navigator.pop(context),
                child: Text('Click me!'),
              ),
            ]
        ),
      ),
    );
  }
}

class PageThree extends StatelessWidget {
  final Map<String, String> args;

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