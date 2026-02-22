import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:connect/services/call_heartbeat_manager.dart';
import 'package:connect/services/user_heartbeat_manager.dart';
import 'package:connect/services/call_limit_manager.dart';
import 'package:connect/globals/navigator_key.dart';
import 'dart:developer' as developer;

class ZegoRoomManager {
  static final ZegoRoomManager _instance = ZegoRoomManager._internal();
  static ZegoRoomManager get instance => _instance;

  ZegoRoomManager._internal();

  StreamSubscription? _connectionStateSubscription;
  VoidCallback? _roomStateListener;
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    _setupRoomStateMonitoring();
    developer.log('ZegoRoomManager initialized', name: 'ZegoRoomManager');
  }

  void _setupRoomStateMonitoring() {
    // Monitor signaling connection state
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = ZegoUIKit()
        .getSignalingPlugin()
        .getConnectionStateStream()
        .listen((state) {
      developer.log('Zego Signaling Connection State: $state',
          name: 'ZegoRoomManager');
    });

    // Monitor room state
    final roomStateNotifier = ZegoUIKit().getRoomStateStream();
    if (_roomStateListener != null) {
      roomStateNotifier.removeListener(_roomStateListener!);
    }

    _roomStateListener = () {
      final state = roomStateNotifier.value;
      final roomId = ZegoUIKit().getRoom().id;

      developer.log(
          'Zego Room State changed: ${state.reason} (Room ID: $roomId)',
          name: 'ZegoRoomManager');

      if (state.reason == ZegoRoomStateChangedReason.Logined) {
        if (roomId.isNotEmpty) {
          developer.log(
              'Room login successful, starting call heartbeat for $roomId',
              name: 'ZegoRoomManager');
          CallHeartbeatManager.instance.start(roomId);
          UserHeartbeatManager.instance.setBusy();
        }
      } else if (state.reason == ZegoRoomStateChangedReason.Logout ||
          state.reason == ZegoRoomStateChangedReason.KickOut ||
          state.reason == ZegoRoomStateChangedReason.ReconnectFailed) {
        developer.log(
            'Room logout/disconnect/kickout (reason: ${state.reason}), stopping call heartbeat',
            name: 'ZegoRoomManager');

        CallHeartbeatManager.instance.stop();
        UserHeartbeatManager.instance.setOnline();
        CallLimitManager.instance.reset(); // Reset call limit and remove banner

        if (state.reason == ZegoRoomStateChangedReason.KickOut ||
            state.reason == ZegoRoomStateChangedReason.ReconnectFailed) {
          developer.log(
              'Call ended due to ${state.reason}, forcing navigation to Home in 500ms',
              name: 'ZegoRoomManager');

          // Delay to allow Zego to attempt its own cleanup first/avoid race conditions
          // But ensure we eventually get to Home
          Future.delayed(const Duration(milliseconds: 500), () {
            _forcePopCallUI();
          });
        } else if (state.reason == ZegoRoomStateChangedReason.Logout) {
          developer.log(
              'Call ended normally (Logout), letting Zego handle navigation',
              name: 'ZegoRoomManager');
          // Do NOT force pop for normal logout to avoid double-pop assertion errors on Caller
        }
      }
    };

    roomStateNotifier.addListener(_roomStateListener!);
  }

  void _forcePopCallUI() {
    try {
      final context = navigatorKey.currentState?.context;
      developer.log(
          'Attempting to force nav to Home. NavigatorState: ${navigatorKey.currentState}, Context: $context',
          name: 'ZegoRoomManager');

      if (context != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          'HomePage',
          (route) => false,
        );
      } else {
        developer.log('Global context is null, cannot navigate',
            name: 'ZegoRoomManager');
      }
    } catch (e) {
      developer.log('Error during force nav: $e', name: 'ZegoRoomManager');
    }
  }

  void dispose() {
    _connectionStateSubscription?.cancel();
    if (_roomStateListener != null) {
      ZegoUIKit().getRoomStateStream().removeListener(_roomStateListener!);
    }
    _isInitialized = false;
  }
}
