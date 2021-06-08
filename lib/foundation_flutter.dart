library foundation_flutter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Screen {
  final String key;
  final Nav? nav;
  final Screen? parent;
  final Widget Function(Map<String, String>) createWidget;

  Screen({
    required this.key,
    this.nav,
    this.parent,
    required this.createWidget
  });

  String url() => '/$key';
}

class Nav {
  final String label;
  final IconData icon;

  Nav(this.label, this.icon);
}

abstract class AbstractTheme {
  ThemeData data();
  ThemeMode mode();
}

class ThemedApplication<T extends AbstractTheme> extends Application {
  final Rx<T> rxTheme;
  T get theme => rxTheme.value;
  set theme(T t) => rxTheme(t);

  ThemedApplication({
    required String title,
    required T initialTheme,
    required List<Screen> screens,
    Transition? tabTransition,
    Transition? internalTransition,
    Widget Function(String)? createHomeWidget
  }):
    rxTheme = initialTheme.obs,
    super(
      title: title,
      theme: initialTheme.data(),
      screens: screens,
      tabTransition: tabTransition,
      internalTransition: internalTransition,
      createHomeWidget: createHomeWidget
    ) {
    Get.changeTheme(initialTheme.data());
    Get.changeThemeMode(initialTheme.mode());
    rxTheme.listen((t) {
      changeTheme(Get.context!, t.data());
      Get.changeTheme(t.data());
      Get.changeThemeMode(t.mode());
      reloadAll();
    });
  }
}

class Application extends StatefulWidget {
  final String title;
  final ThemeData _theme;
  final List<Screen> screens;
  final List<Screen> navScreens;
  final Map<String, Screen> urlMap;
  final String initialURL;
  final Transition tabTransition;
  final Transition internalTransition;
  final Widget Function(String) createHomeWidget;

  late NavService navService;

  Application({
    required this.title,
    required ThemeData theme,
    required this.screens,
    Transition? tabTransition,
    Transition? internalTransition,
    Widget Function(String)? createHomeWidget,
  }) :
        _theme = theme,
        navScreens = screens.where((s) => s.nav != null).toList(),
        urlMap = Map.fromIterable(screens, key: (s) => '/${s.key}', value: (s) => s),
        initialURL = screens[0].url(),
        this.tabTransition = tabTransition ?? Transition.fadeIn,
        this.internalTransition = internalTransition ?? Transition.rightToLeft,
        this.createHomeWidget = createHomeWidget ?? ((s) => Home(initialURL: s));

  Future<dynamic>? reloadScreen() => navService.reloadScreen();

  Future<dynamic>? reloadAll() => navService.reloadAll();

  Future<dynamic>? push(Screen screen, {Map<String, String>? args}) => navService.goToScreen(screen, args ?? Map<String, String>());

  Future<dynamic>? replace(Screen screen, {Map<String, String>? args}) => navService.goToReplacementScreen(screen, args ?? Map<String, String>());

  @override
  State createState() {
    navService = NavService(this);
    return ApplicationState(_theme);
  }

  void changeTheme(BuildContext context, ThemeData theme) {
    final ApplicationState state = Application.of(context)!;
    state.setState(() {
      state.theme = theme;
    });
  }

  ThemeData currentTheme(BuildContext context) => Application.of(context)!.theme;

  static ApplicationState? of(BuildContext context, {bool root = false}) => root
      ? context.findRootAncestorStateOfType<ApplicationState>()
      : context.findAncestorStateOfType<ApplicationState>();
}

class ApplicationState extends State<Application> {
  ThemeData theme;

  ApplicationState(this.theme);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: widget.title,
        theme: theme,
        debugShowCheckedModeBanner: false,
        initialBinding: BindingsBuilder.put(() => widget.navService),
        home: widget.createHomeWidget(widget.initialURL)
    );
  }
}

class NavService extends GetxService {
  final Application app;
  final Rx<Screen> activeScreen;

  NavService(this.app):
        activeScreen = app.screens[0].obs;

  int navIndex() {
    Screen mainScreen = activeScreen();
    while (mainScreen.parent != null) {
      mainScreen = mainScreen.parent!;
    }
    return app.navScreens.indexOf(mainScreen);
  }

  void byNavIndex(int index) => activeScreen(app.navScreens[index]);

  @override
  void onInit() {
    ever(activeScreen, (Screen screen) {
      final String url = screen.url();
      Get.toNamed(url, id: 1, arguments: Map<String, String>());
    });
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void processRouting(Routing? route) {
    final RouteSettings settings = route!.route!.settings;
    if (settings.name != null) {    // Only routes with names
      String url = settings.name!;
      Screen? screen = app.urlMap[url];
      if (screen != null) {
        activeScreen(screen);
      }
    }
  }

  Future<dynamic>? reloadScreen() {
    Get.off(() => activeScreen.value.createWidget({}), id: 1);
  }

  Future<dynamic>? reloadAll() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }
    (Get.context as Element).visitChildren(rebuild);
  }

  Future<dynamic>? goToScreen(Screen screen, Map<String, String> args) {
    if (screen.nav != null) {
      return Get.toNamed(screen.url(), id: 1, arguments: args);
    } else if (screen.parent != null) {
      return Get.toNamed(screen.url(), id: 1, arguments: args);
    } else {
      return Get.to(() => screen.createWidget(args), id: 1, transition: app.internalTransition, arguments: args);
    }
  }

  Future<dynamic>? goToReplacementScreen(Screen screen, Map<String, String> args) {
    if (screen.nav != null) {
      return Get.offNamed(screen.url(), id: 1, arguments: args);
    } else if (screen.parent != null) {
      return Get.offNamed(screen.url(), id: 1, arguments: args);
    } else {
      return Get.off(() => screen.createWidget(args), id: 1, transition: app.internalTransition, arguments: args);
    }
  }

  GetPageRoute onGenerateRoute(RouteSettings settings) {
    final currentUrl = settings.name;
    final Map<String, String> args = (settings.arguments ?? Map<String, String>()) as Map<String, String>;
    final screen = app.urlMap[currentUrl];
    final GetPageBuilder page = () {
      if (screen != null) {
        return screen.createWidget(args);
      } else {
        print('No route for $currentUrl (${app.urlMap.keys}), returning existing');
        return activeScreen.value.createWidget(args);
      }
    };
    return GetPageRoute(
        routeName: currentUrl,
        settings: settings,
        page: page,
        transition: app.tabTransition
    );
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  static int stack = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != '/') {
      stack++;
    }
  }
}

class Home extends GetWidget<NavService> {
  final String _initialURL;

  const Home({Key? key, required String initialURL}):
        _initialURL = initialURL,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: SafeArea(
              child: Navigator(
                key: Get.nestedKey(1),
                initialRoute: _initialURL,
                observers: [
                  GetObserver(controller.processRouting, Get.routing),
                  AppNavigatorObserver()
                ],
                onGenerateRoute: controller.onGenerateRoute,
              )
          ),
          bottomNavigationBar: Obx(
                  () {
                if (controller.navIndex() == -1) {
                  return const SizedBox.shrink();
                }
                return BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: controller.navIndex(),
                  onTap: controller.byNavIndex,
                  items: controller.app.navScreens
                      .map((s) => BottomNavigationBarItem(
                      icon: Icon(s.nav!.icon),
                      label: s.nav!.label
                  )
                  ).toList(),
                );
              }
          ),
        ),
        onWillPop: onWillPop
    );
  }

  Future<bool> onWillPop() async {
    AppNavigatorObserver.stack--;
    if (AppNavigatorObserver.stack <= 0) {
      AppNavigatorObserver.stack = 0;
      return true;
    } else {
      Get.back(id: 1);
      return false;
    }
  }
}