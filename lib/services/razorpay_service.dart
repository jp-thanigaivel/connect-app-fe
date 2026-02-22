import 'package:connect/core/api/api_client.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:connect/services/payment_api_service.dart';
import 'package:connect/models/payment_verification.dart';
import 'package:connect/models/user_profile.dart';
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
    developer.log('Payment Success: ${response.paymentId}',
        name: 'RazorpayService');

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
      developer.log('Payment verification failed: $errorMessage',
          name: 'RazorpayService', error: e);
      onError?.call('Verification failed: $errorMessage');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    developer.log('Payment Error: ${response.code} - ${response.message}',
        name: 'RazorpayService');

    String errorMessage = response.message ?? 'Unknown error';
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment cancelled';
    } else if (errorMessage.toLowerCase() == 'undefined') {
      errorMessage = 'Payment failed';
    }

    onError?.call(errorMessage);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log('External Wallet: ${response.walletName}',
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

      _razorpay.open(options);
    } catch (e) {
      final errorMessage = ApiClient.getErrorMessage(e);
      developer.log('Error during checkout: $errorMessage',
          name: 'RazorpayService', error: e);
      rethrow;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
