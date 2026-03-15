enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerConfig {
  static LogLevel currentLevel =
      LogLevel.debug; // Default to debug for development

  static bool shouldLog(LogLevel level) {
    return level.index >= currentLevel.index;
  }
}
