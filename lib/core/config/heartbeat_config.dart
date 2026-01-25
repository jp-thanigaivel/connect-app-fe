import 'retry_config.dart';

/// Configuration for heartbeat behavior
class HeartbeatConfig {
  /// Interval between heartbeat sends
  final Duration interval;

  /// Retry configuration for heartbeat API calls
  final RetryConfig retryConfig;

  const HeartbeatConfig({
    this.interval = const Duration(seconds: 25),
    this.retryConfig = RetryConfig.standard,
  });

  /// Default configuration for user heartbeat
  static const HeartbeatConfig userDefault = HeartbeatConfig(
    interval: Duration(seconds: 25),
    retryConfig: RetryConfig.standard,
  );

  /// Default configuration for call heartbeat
  static const HeartbeatConfig callDefault = HeartbeatConfig(
    interval: Duration(seconds: 30),
    retryConfig: RetryConfig.standard,
  );

  /// Custom configuration factory
  static HeartbeatConfig custom({
    Duration? interval,
    RetryConfig? retryConfig,
  }) {
    return HeartbeatConfig(
      interval: interval ?? const Duration(seconds: 25),
      retryConfig: retryConfig ?? RetryConfig.standard,
    );
  }
}
