import 'dart:async';
import 'package:connect/services/auth_api_service.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/config/heartbeat_config.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;

class UserHeartbeatManager {
  static final UserHeartbeatManager _instance =
      UserHeartbeatManager._internal();
  static UserHeartbeatManager get instance => _instance;

  UserHeartbeatManager._internal();

  Timer? _heartbeatTimer;
  String _currentStatus = 'online';
  bool _isExpertUser = false;
  final AuthApiService _authApiService = AuthApiService();

  // Configurable heartbeat settings
  HeartbeatConfig _config = HeartbeatConfig.userDefault;

  // Track consecutive failures for debugging
  int _consecutiveFailures = 0;

  /// Start heartbeat with optional custom configuration
  ///
  /// If [config] is not provided, uses [HeartbeatConfig.userDefault]
  Future<void> start({HeartbeatConfig? config}) async {
    developer.log('start() called', name: 'UserHeartbeatManager');

    // Update configuration if provided
    if (config != null) {
      _config = config;
    }

    // Check if user is EXPERT
    developer.log('Checking user type...', name: 'UserHeartbeatManager');
    final userType = await TokenManager.getUserType();
    developer.log('User type: $userType', name: 'UserHeartbeatManager');
    _isExpertUser = userType?.toUpperCase() == 'EXPERT';

    if (!_isExpertUser) {
      developer.log('User is not EXPERT, skipping heartbeat',
          name: 'UserHeartbeatManager');
      return;
    }

    if (_heartbeatTimer != null) {
      developer.log('Stopping existing timer', name: 'UserHeartbeatManager');
      stop();
    }

    developer.log(
        'Starting user heartbeat for EXPERT user (interval: ${_config.interval.inSeconds}s, retries: ${_config.retryConfig.maxRetries})',
        name: 'UserHeartbeatManager');
    _currentStatus = 'online';
    _consecutiveFailures = 0;

    // Send immediate heartbeat
    developer.log('Sending immediate heartbeat', name: 'UserHeartbeatManager');
    _sendHeartbeat();

    // Start periodic heartbeat
    developer.log('Creating Timer.periodic with interval: ${_config.interval}',
        name: 'UserHeartbeatManager');
    _heartbeatTimer = Timer.periodic(_config.interval, (timer) {
      developer.log(
          'Heartbeat timer tick (Running in ${WidgetsBinding.instance.lifecycleState})',
          name: 'UserHeartbeatManager');
      // Don't await - let it run in background to avoid blocking timer
      _sendHeartbeat();
    });

    developer.log(
        'Timer created successfully. Timer active: ${_heartbeatTimer?.isActive}',
        name: 'UserHeartbeatManager');
  }

  void stop() {
    if (_heartbeatTimer != null) {
      developer.log('Stopping user heartbeat', name: 'UserHeartbeatManager');
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _currentStatus = 'online';
      _consecutiveFailures = 0;
    }
  }

  void setBusy() {
    if (!_isExpertUser) return;

    if (_currentStatus != 'busy') {
      developer.log('Setting user status to busy',
          name: 'UserHeartbeatManager');
      _currentStatus = 'busy';
      _sendHeartbeat();
    }
  }

  void setOnline() {
    if (!_isExpertUser) return;

    if (_currentStatus != 'online') {
      developer.log('Setting user status to online',
          name: 'UserHeartbeatManager');
      _currentStatus = 'online';
      _sendHeartbeat();
    }
  }

  /// Update heartbeat configuration
  ///
  /// This will apply to the next heartbeat cycle.
  /// To apply immediately, call [stop] and then [start] with the new config.
  void updateConfig(HeartbeatConfig config) {
    _config = config;
    developer.log(
        'Updated heartbeat config: interval=${config.interval.inSeconds}s, retries=${config.retryConfig.maxRetries}',
        name: 'UserHeartbeatManager');
  }

  Future<void> _sendHeartbeat() async {
    if (!_isExpertUser) return;

    try {
      developer.log(
          'Sending heartbeat (status: $_currentStatus, consecutive failures: $_consecutiveFailures)',
          name: 'UserHeartbeatManager');

      // Retry logic is now handled by ApiClient
      await _authApiService.sendHeartbeat(
        status: _currentStatus == 'busy' ? 'busy' : null,
        retryConfig: _config.retryConfig,
      );

      // Success - reset failure counter
      if (_consecutiveFailures > 0) {
        developer.log(
            'Heartbeat recovered after $_consecutiveFailures consecutive failures',
            name: 'UserHeartbeatManager');
        _consecutiveFailures = 0;
      }
    } catch (e) {
      _consecutiveFailures++;

      // Log error with failure count
      developer.log(
          'Heartbeat failed (consecutive failures: $_consecutiveFailures): $e',
          name: 'UserHeartbeatManager');

      // IMPORTANT: Don't stop the timer - keep trying
      // The timer will continue and retry on next interval
      // This ensures heartbeat resumes when backend comes back online
    }
  }
}
