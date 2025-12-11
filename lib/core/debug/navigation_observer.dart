import 'package:flutter/widgets.dart';
import 'debug_logger.dart';

class LoggingNavigatorObserver extends NavigatorObserver {
  final _log = DebugLogger();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.log('PUSH ${route.settings.name ?? route.runtimeType}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.log('POP ${route.settings.name ?? route.runtimeType}');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log.log(
        'REPLACE ${oldRoute?.settings.name ?? oldRoute?.runtimeType} -> ${newRoute?.settings.name ?? newRoute?.runtimeType}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
