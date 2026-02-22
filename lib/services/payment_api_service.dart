import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/payment_order.dart';
import 'package:connect/models/payment_verification.dart';
import 'package:connect/models/wallet_balance.dart';
import 'package:connect/models/transaction.dart';
import 'dart:developer' as developer;

class PaymentApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> getConversionRate() async {
    try {
      final response = await _apiClient.get(ApiConstants.conversionRate);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log('Error fetching conversion rate: $e',
          name: 'PaymentApiService');
      rethrow;
    }
  }

  Future<ApiResponse<PaymentOrder>> createOrder(
      double amount, String currency, String description,
      {String? promotionCode}) async {
    try {
      final Map<String, dynamic> data = {
        'requestAmount': {
          'price': amount.toInt() == amount
              ? amount.toInt().toString()
              : amount.toString(),
          'currency': currency,
        },
        'description': description,
      };

      if (promotionCode != null) {
        data['promotionCode'] = promotionCode;
      }

      final response = await _apiClient.post(
        ApiConstants.createOrder,
        data: data,
      );

      return ApiResponse<PaymentOrder>.fromJson(
        response.data,
        (json) => PaymentOrder.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      final errorMessage = ApiClient.getErrorMessage(e);
      developer.log('Error creating payment order: $errorMessage',
          name: 'PaymentApiService', error: e);
      rethrow;
    }
  }

  Future<ApiResponse<void>> verifyPayment(
      PaymentVerification verification) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyPayment,
        data: verification.toJson(),
      );

      return ApiResponse<void>.fromJson(
        response.data,
        (json) {},
      );
    } catch (e) {
      developer.log('Error verifying payment: $e', name: 'PaymentApiService');
      rethrow;
    }
  }

  Future<ApiResponse<WalletBalance>> getWalletBalance() async {
    try {
      final response = await _apiClient.get(ApiConstants.walletBalance);

      return ApiResponse<WalletBalance>.fromJson(
        response.data,
        (json) => WalletBalance.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      developer.log('Error fetching wallet balance: $e',
          name: 'PaymentApiService');
      rethrow;
    }
  }

  Future<ApiResponse<List<Transaction>>> getPaymentHistory({
    String? nextCursor,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (nextCursor != null) queryParams['nextCursor'] = nextCursor;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (startDate != null) {
        queryParams['createdOn__gte'] = startDate.toString().split(' ')[0];
      }
      if (endDate != null) {
        queryParams['createdOn__lte'] = endDate.toString().split(' ')[0];
      }

      final response = await _apiClient.get(
        ApiConstants.paymentHistory,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return ApiResponse<List<Transaction>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => Transaction.fromJson(e)).toList(),
      );
    } catch (e) {
      developer.log('Error fetching payment history: $e',
          name: 'PaymentApiService');
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPaymentSearchConfig() async {
    try {
      final response = await _apiClient.get(ApiConstants.paymentSearchConfig);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log('Error fetching payment search config: $e',
          name: 'PaymentApiService');
      rethrow;
    }
  }

  Future<ApiResponse<Transaction>> getOrderStatus(String gatewayOrderId) async {
    try {
      final response = await _apiClient
          .get('/connect/app/api/v1/payment/order/$gatewayOrderId');
      return ApiResponse<Transaction>.fromJson(
        response.data,
        (json) => Transaction.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      final errorMessage = ApiClient.getErrorMessage(e);
      developer.log('Error fetching order status: $errorMessage',
          name: 'PaymentApiService', error: e);
      rethrow;
    }
  }
}
