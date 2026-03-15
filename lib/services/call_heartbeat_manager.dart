import 'dart:async';
import 'package:connect/services/call_api_service.dart';
import 'package:connect/core/config/heartbeat_config.dart';
import 'package:connect/core/utils/app_logger.dart';

import 'dart:developer' as developer;

class CallHeartbeatManager {
  static final CallHeartbeatManager _instance =
      CallHeartbeatManager._internal();
  static CallHeartbeatManager get instance => _instance;

  CallHeartbeatManager._internal();

  Timer? _heartbeatTimer;
  String? _currentCallSessionId;
  final CallApiService _callApiService = CallApiService();

  // Configurable heartbeat settings
  HeartbeatConfig _config = HeartbeatConfig.callDefault;

  // Track consecutive failures for debugging
  int _consecutiveFailures = 0;

  /// Start call heartbeat with optional custom configuration
  ///
  /// If [config] is not provided, uses [HeartbeatConfig.callDefault]
  void start(String callSessionId, {HeartbeatConfig? config}) {
    if (callSessionId.isEmpty) {
      AppLogger.info('Warning: Attempted to start call heartbeat with empty session ID', name: 'CallHeartbeatManager');
      return;
    }

    if (_heartbeatTimer != null && _currentCallSessionId == callSessionId) {
      AppLogger.info('Heartbeat already running for session: $callSessionId', name: 'CallHeartbeatManager');
      return;
    }

    if (_heartbeatTimer != null) {
      stop();
    }

    AppLogger.info('Starting call heartbeat for session: $callSessionId (interval: ${_config.interval.inSeconds}s, retries: ${_config.retryConfig.maxRetries})', name: 'CallHeartbeatManager');
    _currentCallSessionId = callSessionId;
    _consecutiveFailures = 0;

    // Send immediate heartbeat
    AppLogger.info('Sending first immediate heartbeat for session: $callSessionId', name: 'CallHeartbeatManager');
    _sendHeartbeat();

    // Start periodic heartbeat
    _heartbeatTimer = Timer.periodic(_config.interval, (timer) {
      AppLogger.info('Call heartbeat timer tick', name: 'CallHeartbeatManager');
      // Don't await - let it run in background to avoid blocking timer
      _sendHeartbeat();
    });
  }

  void stop() {
    if (_heartbeatTimer != null) {
      AppLogger.info('Stopping call heartbeat', name: 'CallHeartbeatManager');
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _currentCallSessionId = null;
      _consecutiveFailures = 0;
    }
  }

  /// Update heartbeat configuration
  ///
  /// This will apply to the next heartbeat cycle.
  /// To apply immediately, call [stop] and then [start] with the new config.
  void updateConfig(HeartbeatConfig config) {
    _config = config;
    AppLogger.info('Updated call heartbeat config: interval=${config.interval.inSeconds}s, retries=${config.retryConfig.maxRetries}', name: 'CallHeartbeatManager');
  }

  Future<void> _sendHeartbeat() async {
    if (_currentCallSessionId == null) return;

    try {
      AppLogger.info('Sending call heartbeat (session: $_currentCallSessionId, consecutive failures: $_consecutiveFailures)', name: 'CallHeartbeatManager');

      // Retry logic is now handled by ApiClient
      await _callApiService.sendHeartbeat(
        _currentCallSessionId!,
        retryConfig: _config.retryConfig,
      );

      // Success - reset failure counter
      if (_consecutiveFailures > 0) {
        AppLogger.info('Call heartbeat recovered after $_consecutiveFailures consecutive failures', name: 'CallHeartbeatManager');
        _consecutiveFailures = 0;
      }
    } catch (e) {
      _consecutiveFailures++;

      // Log error with failure count
      AppLogger.error('Call heartbeat failed (consecutive failures: $_consecutiveFailures): $e', name: 'CallHeartbeatManager');

      // IMPORTANT: Don't stop the timer - keep trying
      // The timer will continue and retry on next interval
    }
  }
}
