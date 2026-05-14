import 'package:flutter/material.dart';
import '../services/screen_tracker.dart';

class ApiNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordScreenName(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _recordScreenName(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _recordScreenName(previousRoute);
  }

  void _recordScreenName(Route<dynamic> route) {
    debugPrint('ApiDebugger Navigator: Route pushed/popped');
    debugPrint('  - Route Name: ${route.settings.name}');
    debugPrint('  - Route Arguments: ${route.settings.arguments}');
    debugPrint('  - Route Object: $route');
    // 1. If name is provided by the developer, use it.
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      ScreenTracker().updateScreen(route.settings.name);
      return;
    }

    if (route is MaterialPageRoute) {
      final widget = route.builder(route.navigator!.context);
      ScreenTracker().updateScreen(widget.runtimeType.toString());
      return;
    }
  }
}
