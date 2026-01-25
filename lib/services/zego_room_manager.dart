import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:connect/services/call_heartbeat_manager.dart';
import 'package:connect/services/user_heartbeat_manager.dart';
import 'package:connect/main.dart';
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

        if (state.reason == ZegoRoomStateChangedReason.KickOut) {
          developer.log(
              'User was kicked out, forcing navigator pop via global key',
              name: 'ZegoRoomManager');
          _forcePopCallUI();
        }
      }
    };

    roomStateNotifier.addListener(_roomStateListener!);
  }

  void _forcePopCallUI() {
    try {
      final context = navigatorKey.currentState?.context;
      if (context != null) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          developer.log('Popping call UI from global context',
              name: 'ZegoRoomManager');
          navigator.pop();
        } else {
          developer.log(
              'Navigator cannot pop - already at root or specialized state',
              name: 'ZegoRoomManager');
        }
      } else {
        developer.log('Global context is null, cannot pop',
            name: 'ZegoRoomManager');
      }
    } catch (e) {
      developer.log('Error during force pop: $e', name: 'ZegoRoomManager');
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
