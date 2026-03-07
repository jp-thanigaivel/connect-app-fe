import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/services/payment_api_service.dart';
import 'package:connect/services/notification_service.dart';
import 'package:connect/services/promotion_api_service.dart';
import 'package:connect/components/promotion_popup.dart';
import 'package:connect/models/promotion.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'dart:developer' as developer;
import 'package:connect/globals/navigator_key.dart';

class CallLimitManager {
  static final CallLimitManager _instance = CallLimitManager._internal();
  static CallLimitManager get instance => _instance;
  CallLimitManager._internal();

  final PaymentApiService _paymentApiService = PaymentApiService();
  final PromotionApiService _promotionApiService = PromotionApiService();

  // Configurable warning intervals in seconds
  final List<int> warningIntervals = [45, 20];
  final Set<int> _triggeredIntervals = {};

  double? _allowedSeconds;
  double? _pricePerMinute;
  bool _isEndUser = false;
  bool _isRefreshing = false;
  bool _gracePeriodStarted = false;
  DateTime? _graceStartTime;

  // Persistent in-app banner state
  final ValueNotifier<String?> bannerNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<Offset> bannerPositionNotifier =
      ValueNotifier<Offset>(const Offset(16, 60));

  void reset() {
    _allowedSeconds = null;
    _pricePerMinute = null;
    _triggeredIntervals.clear();
    _isEndUser = false;
    _isRefreshing = false;
    _gracePeriodStarted = false;
    _graceStartTime = null;
    _removeBanner();
    bannerPositionNotifier.value = const Offset(16, 60);
  }

  void _removeBanner() {
    bannerNotifier.value = null;
  }

  Future<void> initCallLimit(double coins, double pricePerMinute) async {
    reset();
    final userType = await TokenManager.getUserType();
    _isEndUser = userType == 'ENDUSER';
    _pricePerMinute = pricePerMinute;

    if (_isEndUser && pricePerMinute > 0) {
      _allowedSeconds = (coins / pricePerMinute) * 60;
      developer.log(
          'Call limit initialized: $_allowedSeconds seconds ($coins coins @ $pricePerMinute/min)',
          name: 'CallLimitManager');
    }
  }

  Future<void> checkDuration(
      Duration duration, ZegoUIKitPrebuiltCallController controller) async {
    if (!_isEndUser || _allowedSeconds == null || _pricePerMinute == null)
      return;

    final currentSeconds = duration.inSeconds.toDouble();
    final remainingSeconds = _allowedSeconds! - currentSeconds;

    // 1. Configurable low balance warnings
    for (final interval in warningIntervals) {
      if (remainingSeconds <= interval &&
          remainingSeconds > 0 &&
          !_triggeredIntervals.contains(interval)) {
        _triggeredIntervals.add(interval);
        _showLowBalanceWarning(interval);
      }
    }

    // 2. Out of balance - try refresh once
    if (remainingSeconds <= 0 && !_isRefreshing && !_gracePeriodStarted) {
      _isRefreshing = true;
      developer.log('Balance reached zero, refreshing...',
          name: 'CallLimitManager');
      await _refreshBalance(currentSeconds);
      _isRefreshing = false;

      // If after refresh we still have <= 0, start grace period
      if (_allowedSeconds! <= currentSeconds) {
        _gracePeriodStarted = true;
        _graceStartTime = DateTime.now();
        developer.log('Grace period started for 1 minute.',
            name: 'CallLimitManager');
      } else {
        // We got more balance, reset intervals that are now in the future
        _triggeredIntervals.removeWhere(
            (interval) => (_allowedSeconds! - currentSeconds) > interval);
        if (_allowedSeconds! - currentSeconds > 60) {
          _removeBanner();
        }
      }
    }

    // 3. Grace period check (1 minute)
    if (_gracePeriodStarted && _graceStartTime != null) {
      final graceElapsed =
          DateTime.now().difference(_graceStartTime!).inSeconds;

      // Try refresh balance occasionally during grace period too (e.g. every 20s)
      if (graceElapsed > 0 && graceElapsed % 20 == 0 && !_isRefreshing) {
        _isRefreshing = true;
        final newBalance = await _refreshBalance(currentSeconds);
        _isRefreshing = false;

        // If balance is enough for at least 1 more minute
        if (newBalance != null && newBalance >= _pricePerMinute!) {
          _gracePeriodStarted = false;
          _graceStartTime = null;
          // Recalculate which triggers should be re-enabled
          _triggeredIntervals.removeWhere(
              (interval) => (_allowedSeconds! - currentSeconds) > interval);
          _removeBanner();
          developer.log(
              'Balance replenished ($newBalance coins) during grace period. Resuming normal monitoring.',
              name: 'CallLimitManager');
          return;
        }
      }

      if (graceElapsed >= 60) {
        developer.log('Grace period ended. Hanging up.',
            name: 'CallLimitManager');
        controller.hangUp(navigatorKey.currentState!.context);
        reset();
      }
    }
  }

  Future<double?> _refreshBalance(double currentSeconds) async {
    try {
      final response = await _paymentApiService.getWalletBalance();
      if (response.data != null && _pricePerMinute != null) {
        final newBalance = response.data!.balance.toDouble();
        // Recalculate total allowed seconds from call start
        _allowedSeconds = currentSeconds + (newBalance / _pricePerMinute!) * 60;
        developer.log(
            'Balance refreshed: $newBalance coins. New total allowed seconds: $_allowedSeconds',
            name: 'CallLimitManager');
        return newBalance;
      }
    } catch (e) {
      developer.log('Error refreshing balance during call: $e',
          name: 'CallLimitManager');
    }
    return null;
  }

  void _showLowBalanceWarning(int seconds) {
    // 1. System Notification (Heads-up)
    NotificationService.instance.showHeadsUpNotification(
      title: 'Low Balance Warning',
      body: 'Call will end in $seconds seconds. Please recharge to continue.',
    );

    // 2. Persistent In-App Banner
    _showPersistentBanner('Low Balance: $seconds seconds left!');
  }

  void _showPersistentBanner(String message) {
    bannerNotifier.value = message;
  }

  void handleRechargeAction() {
    _handleRechargeAction();
  }

  void dismissBanner() {
    _removeBanner();
  }

  void updatePosition(Offset delta) {
    bannerPositionNotifier.value += delta;
  }

  Future<void> _handleRechargeAction() async {
    developer.log('Add Coins button clicked', name: 'CallLimitManager');
    final context = navigatorKey.currentState?.context;
    if (context == null) {
      developer.log('Navigation context is null!', name: 'CallLimitManager');
      return;
    }

    try {
      // Check for promotions first
      developer.log('Fetching promotions...', name: 'CallLimitManager');
      final promoResponse = await _promotionApiService.getPromotions();
      final promotions = promoResponse.data ?? [];
      developer.log('Found ${promotions.length} promotions',
          name: 'CallLimitManager');

      if (context.mounted) {
        if (promotions.isNotEmpty) {
          developer.log('Showing promotion popup', name: 'CallLimitManager');
          PromotionPopup
              .resetShownFlag(); // Reset to ensure it shows for this action
          PromotionPopup.show(context, promotions, (promo) {
            developer.log('Promotion selected: ${promo.promotionCode}',
                name: 'CallLimitManager');
            _navigateToProfileRecharge(context, promotion: promo);
          });
          // Also hide the banner since they are now in the recharge flow
          dismissBanner();
        } else {
          developer.log('No promotions found, navigating to Profile',
              name: 'CallLimitManager');
          _navigateToProfileRecharge(context);
          dismissBanner();
        }
      }
    } catch (e) {
      developer.log('Error handling recharge action: $e',
          name: 'CallLimitManager');
      if (context.mounted) {
        _navigateToProfileRecharge(context);
        dismissBanner();
      }
    }
  }

  void _navigateToProfileRecharge(BuildContext context,
      {Promotion? promotion}) {
    Navigator.pushNamed(
      context,
      'ProfilePage',
      arguments: {
        'autoOpenRecharge': true,
        'promotion': promotion,
      },
    );
  }
}
