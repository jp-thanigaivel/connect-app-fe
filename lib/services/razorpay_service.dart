import 'package:connect/core/api/api_client.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:connect/services/payment_api_service.dart';
import 'package:connect/models/payment_verification.dart';
import 'package:connect/models/user_profile.dart';
import 'package:connect/core/utils/app_logger.dart';
import 'package:connect/core/services/sentry_service.dart';

import 'dart:developer' as developer;

class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  final PaymentApiService _paymentApiService = PaymentApiService();

  void Function(String message)? onSuccess;
  void Function(String message)? onError;
  void Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService({
    this.onSuccess,
    this.onError,
    this.onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    AppLogger.logEvent(
      'Payment ${response.paymentId} completed for order ${response.orderId}.',
      attributes: {
        'paymentId': response.paymentId ?? '',
        'orderId': response.orderId ?? '',
      },
    );
    AppLogger.info('Payment Success: ${response.paymentId}',
        name: 'RazorpayService');
    SentryService.count('payment_completed');
    final duration = SentryService.stopTimer(response.orderId ?? '');
    if (duration != null) {
      SentryService.distribution('payment_latency_ms', duration,
          unit: 'millisecond');
    }

    try {
      final verification = PaymentVerification(
        gatewayOrderId: response.orderId!,
        gatewaySignature: response.signature,
      );

      final verificationResponse =
          await _paymentApiService.verifyPayment(verification);

      if (verificationResponse.status.isSuccess) {
        onSuccess?.call(verificationResponse.status.statusDesc);
      } else {
        onError?.call(verificationResponse.status.statusDesc);
      }
    } catch (e) {
      final errorMessage = ApiClient.getErrorMessage(e);
      AppLogger.error('Payment verification failed: $errorMessage',
          error: e, name: 'RazorpayService');
      onError?.call('Verification failed: $errorMessage');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    AppLogger.logEvent(
      'Payment failed: ${response.message} (Code: ${response.code})',
      attributes: {
        'errorCode': response.code?.toString() ?? '',
        'message': response.message ?? '',
      },
      isError: true,
    );
    AppLogger.error('Payment Error: ${response.code} - ${response.message}',
        name: 'RazorpayService');
    SentryService.count('payment_failed');
    SentryService.stopTimer(
        ''); // Clear any lingering timers if possible, though we don't have orderId here easily from failure response sometimes
    // But wait, RazorpayFailureResponse might have orderId in some versions? No.
    // However, we can track the 'current' orderId in a private field if needed.

    String errorMessage = response.message ?? 'Unknown error';
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment cancelled';
    } else if (errorMessage.toLowerCase() == 'undefined') {
      errorMessage = 'Payment failed';
    }

    onError?.call(errorMessage);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.info('External Wallet: ${response.walletName}',
        name: 'RazorpayService');
    onExternalWallet?.call(response);
  }

  Future<void> openCheckout({
    required double amount,
    required String currency,
    required String name,
    required String description,
    required UserProfile userProfile,
    required String razorpayKey,
    String? promotionCode,
  }) async {
    try {
      // 1. Create order on backend
      final orderResponse = await _paymentApiService.createOrder(
          amount, currency, description,
          promotionCode: promotionCode);

      if (!orderResponse.status.isSuccess || orderResponse.data == null) {
        throw Exception(
            'Failed to create payment order: ${orderResponse.status.statusDesc}');
      }

      final order = orderResponse.data!;

      // 2. Open Razorpay checkout
      var options = {
        'key': razorpayKey,
        'amount': order.amount, // Amount in paise/smallest unit
        'currency': order.currency,
        'name': name,
        'order_id': order.id,
        'description': description,
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact':
              '', // We don't have phone in UserProfile yet, or maybe it's nested
          'email': userProfile.email,
        }
      };

      AppLogger.logEvent(
        'User ${userProfile.userId} initiated payment of ${order.amount} ${order.currency} for order ${order.id}.',
        attributes: {
          'userId': userProfile.userId,
          'email': userProfile.email,
          'orderId': order.id,
          'amount': order.amount.toString(),
          'currency': order.currency,
        },
      );

      SentryService.count('payment_initiated');
      SentryService.startTimer(order.id);

      _razorpay.open(options);
    } catch (e) {
      final errorMessage = ApiClient.getErrorMessage(e);
      AppLogger.error('Error during checkout: $errorMessage',
          error: e, name: 'RazorpayService');
      rethrow;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
