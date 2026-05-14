import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/http_overrides.dart';
import 'models/smtp_config.dart';
import 'services/api_log_service.dart';
import 'observers/api_navigator_observer.dart';
import 'ui/api_session_list_screen.dart';
export 'widgets/api_debugger_wrapper.dart';
export 'observers/api_navigator_observer.dart';

class ApiDebugger {
  /// Initialize the API Debugger.
  /// Set [enableInRelease] to true if you want the debugger to work in release mode.
  /// Set [initiallyEnabled] to override the persisted state on launch.
  /// If [initiallyEnabled] is null (default), the last persisted state will be used.
  /// Note: Interception is NOT supported on Web.
  static Future<void> initialize({
    bool enableInRelease = false,
    bool? initiallyEnabled,
    SmtpConfig? smtpConfig,
  }) async {
    if (kIsWeb) {
      debugPrint('ApiDebugger: Web is not supported.');
      return;
    }

    if (kReleaseMode && !enableInRelease) {
      return;
    }

    HttpOverrides.global = LoggingHttpOverrides();

    // 1. Load persisted state from storage
    await ApiLogService().init();

    // 2. Set SMTP configuration
    ApiLogService().setSmtpConfig(smtpConfig);

    // 2. ONLY override if the user explicitly passed true or false
    if (initiallyEnabled != null) {
      if (initiallyEnabled) {
        await ApiLogService().enable();
      } else {
        await ApiLogService().disable();
      }
      debugPrint(
          'ApiDebugger: [INIT] Overridden by initiallyEnabled: $initiallyEnabled');
    }

    debugPrint(
        'ApiDebugger: [FINAL] Ready. Logging is ${ApiLogService().isEnabled ? 'ON' : 'OFF'}');
  }

  /// Enable the logger manually.
  static Future<void> enable() async {
    await ApiLogService().enable();
  }

  /// Disable the logger manually.
  static Future<void> disable() async {
    await ApiLogService().disable();
  }

  /// Check if the logger is currently enabled.
  static bool get isEnabled => ApiLogService().isEnabled;

  /// Returns a NavigatorObserver to track screen transitions.
  static NavigatorObserver navigatorObserver() {
    return ApiNavigatorObserver();
  }

  /// A helper to create a [MaterialPageRoute] that automatically sets the
  /// route name to the widget's class name for the debugger.
  static Route<T> route<T>(Widget page) {
    return MaterialPageRoute<T>(
      settings: RouteSettings(name: page.runtimeType.toString()),
      builder: (context) => page,
    );
  }

  /// Opens the API Session List screen.
  static void open(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) {
      debugPrint('ApiDebugger Error: Could not find Navigator in context. '
          'Ensure ApiDebuggerWrapper is inside MaterialApp or a Navigator-enabled context.');
      return;
    }

    if (!ApiLogService().isInitialized) {
      debugPrint('ApiDebugger Warning: ApiDebugger.initialize() was not called in main(). '
          'Persistence and some features may not work correctly.');
    }

    if (HttpOverrides.current is! LoggingHttpOverrides) {
      debugPrint('ApiDebugger Warning: HttpOverrides.current is not LoggingHttpOverrides. '
          'API calls will NOT be intercepted. Ensure ApiDebugger.initialize() is called in main().');
    }

    navigator.push(
      MaterialPageRoute(
        builder: (context) => const ApiSessionListScreen(),
        settings: const RouteSettings(name: 'ApiSessionListScreen'),
      ),
    );
  }
}
