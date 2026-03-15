import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

import 'package:connect/models/user_context.dart';

class SentryService {
  static final Map<String, DateTime> _timers = {};
  static UserContext? _currentUser;

  static Future<void> init({
    required String dsn,
    required VoidCallback appRunner,
    bool debug = false,
  }) async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 1.0;
        options.debug = debug;
        if (debug) {
          options.diagnosticLevel = SentryLevel.debug;
        }
        options.enableLogs = true;
      },
      appRunner: appRunner,
    );
  }

  static void setUserContext(UserContext user) {
    _currentUser = user;
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: user.userId));
      scope.setContexts('user_context', user.toSentryContext());
    });
  }

  static Future<Map<String, dynamic>> _getEnrichedAttributes() async {
    final info = await PackageInfo.fromPlatform();

    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceModel = androidInfo.model;
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceModel = iosInfo.utsname.machine;
      osVersion = 'iOS ${iosInfo.systemVersion}';
    }

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'environment': kDebugMode ? 'development' : 'production',
      'app_version': '${info.version}+${info.buildNumber}',
      'platform': Platform.operatingSystem,
      'device_model': deviceModel,
      'os_version': osVersion,
      if (_currentUser != null) ...{
        'userId': _currentUser!.userId,
        'orgId': _currentUser!.orgId,
        'businessUnitId': _currentUser!.businessUnitId,
      },
    };
  }

  static void captureException(dynamic error, {StackTrace? stackTrace}) async {
    final enriched = await _getEnrichedAttributes();

    // Log the exception as an error in the Logs tab as well
    logEvent(
      'Exception: ${error.toString()}',
      attributes: {
        'error': error.toString(),
        'stackTrace': stackTrace?.toString() ?? 'No stacktrace',
        ...enriched,
      },
      isError: true,
    );

    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        enriched.forEach((key, value) {
          scope.setContexts(key, value);
        });
      },
    );
  }

  static void logEvent(
    String eventName, {
    Map<String, dynamic>? attributes,
    bool isError = false,
  }) async {
    final sentryAttributes = await _getMergedSentryAttributes(attributes);

    if (isError) {
      Sentry.logger.error(
        eventName,
        attributes: sentryAttributes.isNotEmpty ? sentryAttributes : null,
      );
      // Fallback for Issues tab
      Sentry.captureMessage(
        eventName,
        level: SentryLevel.error,
        withScope: (scope) {
          sentryAttributes.forEach((key, value) {
            scope.setContexts(key, value);
          });
        },
      );
    } else {
      Sentry.logger.info(
        eventName,
        attributes: sentryAttributes.isNotEmpty ? sentryAttributes : null,
      );
      // For info logs, we only use the Logs tab to avoid cluttering the Issues tab
    }
  }

  static Future<Map<String, SentryAttribute>> _getMergedSentryAttributes(
      Map<String, dynamic>? attributes) async {
    final enriched = await _getEnrichedAttributes();
    final combined = {
      if (attributes != null) ...attributes,
      ...enriched,
    };

    final result = <String, SentryAttribute>{};
    combined.forEach((key, value) {
      result[key] = SentryAttribute.string(value?.toString() ?? 'null');
    });
    return result;
  }

  static void count(String name,
      {int value = 1, Map<String, dynamic>? attributes}) async {
    final sentryAttrs = await _getMergedSentryAttributes(attributes);
    Sentry.metrics.count(name, value, attributes: sentryAttrs);
  }

  static void gauge(String name, double value,
      {Map<String, dynamic>? attributes}) async {
    final sentryAttrs = await _getMergedSentryAttributes(attributes);
    Sentry.metrics.gauge(name, value, attributes: sentryAttrs);
  }

  static void distribution(String name, double value,
      {String? unit, Map<String, dynamic>? attributes}) async {
    final sentryAttrs = await _getMergedSentryAttributes(attributes);
    Sentry.metrics
        .distribution(name, value, unit: unit, attributes: sentryAttrs);
  }

  static void startTimer(String key) {
    _timers[key] = DateTime.now();
  }

  static double? stopTimer(String key) {
    final start = _timers.remove(key);
    if (start == null) return null;
    return DateTime.now().difference(start).inMilliseconds.toDouble();
  }
}
