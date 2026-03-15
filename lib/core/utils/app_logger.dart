import 'package:connect/core/services/sentry_service.dart';
import 'dart:developer' as developer;
import 'package:connect/core/config/logger_config.dart';

class AppLogger {
  static void debug(String message, {String? name}) {
    if (LoggerConfig.shouldLog(LogLevel.debug)) {
      developer.log('[DEBUG] $message', name: name ?? 'AppLogger');
    }
  }

  static void info(String message, {String? name}) {
    if (LoggerConfig.shouldLog(LogLevel.info)) {
      developer.log('[INFO] $message', name: name ?? 'AppLogger');
    }
  }

  static void warning(String message, {String? name}) {
    if (LoggerConfig.shouldLog(LogLevel.warning)) {
      developer.log('[WARN] $message', name: name ?? 'AppLogger');
    }
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) {
    if (LoggerConfig.shouldLog(LogLevel.error)) {
      developer.log(
        '[ERROR] $message',
        error: error,
        stackTrace: stackTrace,
        name: name ?? 'AppLogger',
      );
    }

    // Always report actual errors/exceptions to Sentry regardless of local console config
    SentryService.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
    );
  }

  /// Logs a business or lifecycle event directly to Sentry with detailed context.
  static void logEvent(String eventName,
      {Map<String, dynamic>? attributes, String? name, bool isError = false}) {
    if (LoggerConfig.shouldLog(LogLevel.info)) {
      developer.log('[EVENT] $eventName',
          error: attributes, name: name ?? 'AppLogger');
    }

    SentryService.logEvent(
      eventName,
      attributes: attributes,
      isError: isError,
    );
  }
}
