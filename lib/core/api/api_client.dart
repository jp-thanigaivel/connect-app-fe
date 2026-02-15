import 'package:dio/dio.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/config/retry_config.dart';
import 'package:connect/globals/navigator_key.dart'; // Import to access navigatorKey
import 'package:flutter/material.dart'; // Import for SnackBar
import 'package:connect/core/utils/ui_utils.dart';
import 'dart:developer' as developer;

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _handleSemanticError(response);
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final statusCode = e.response?.statusCode;
          final dynamic responseData = e.response?.data;
          final dynamic statusObject =
              responseData is Map ? responseData['status'] : null;
          final String message = (statusObject is Map
                  ? statusObject['statusDesc']?.toString()
                  : null) ??
              _getFriendlyErrorMessage(e);

          developer.log(
            'API Error: [$statusCode] $message',
            name: 'ApiClient',
            error: responseData,
          );

          if (statusCode == 401 || statusCode == 403) {
            developer.log(
                'Unauthorized access ($statusCode) - logging out user',
                name: 'ApiClient');

            // 1. Clear tokens
            TokenManager.clearTokens().then((_) {
              // 2. Navigate to Login Page
              UiUtils.showErrorSnackBar('Session expired. Please login again.');

              // Route to login
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                'LoginPage',
                (route) => false,
              );
            });
          } else {
            // Show global error for other types of failures
            _showErrorSnackBar(message);
          }

          return handler.next(e);
        },
      ),
    );
  }

  void _handleSemanticError(Response response) {
    if (response.data is Map<String, dynamic>) {
      final status = response.data['status'];
      if (status != null && status is Map<String, dynamic>) {
        final statusCodeStr =
            status['statusCode']?.toString() ?? status['errorCode']?.toString();
        final statusDesc = status['statusDesc']?.toString();

        if (statusCodeStr != null &&
            !statusCodeStr.startsWith('2') &&
            statusDesc != null) {
          developer.log(
              'Semantic Error detected in 200 response: [$statusCodeStr] $statusDesc',
              name: 'ApiClient');
          _showErrorSnackBar(statusDesc);
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    UiUtils.showErrorSnackBar(message);
  }

  static String getErrorMessage(dynamic e) {
    if (e is DioException) {
      final dynamic responseData = e.response?.data;
      if (responseData is Map && responseData['status'] != null) {
        return responseData['status']['statusDesc']?.toString() ??
            'An unknown error occurred';
      }
      return 'Request failed (${e.response?.statusCode ?? 'unknown error'}).';
    }
    return e.toString().contains('Exception:')
        ? e.toString().split('Exception:').last
        : 'An error occurred. Please try again.';
  }

  String _getFriendlyErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please try again later.';
      case DioExceptionType.badResponse:
        if (statusCode != null) {
          if (statusCode >= 500) {
            return 'Server error ($statusCode). Please try again later.';
          } else if (statusCode == 404) {
            return 'Requested resource not found (404).';
          } else if (statusCode >= 400) {
            return 'Request failed ($statusCode). please check your input.';
          }
        }
        return 'Server returned an error. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'A network error occurred. Please check your connection.';
    }
  }

  /// Generic retry wrapper for API calls
  ///
  /// Executes [apiCall] with retry logic based on [retryConfig].
  /// If [retryConfig] is null or RetryConfig.none, no retries are performed.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() apiCall,
    RetryConfig? retryConfig,
    String operationName,
  ) async {
    // No retry if config is null or maxRetries is 0
    if (retryConfig == null || retryConfig.maxRetries == 0) {
      return await apiCall();
    }

    int attemptNumber = 0;
    while (attemptNumber <= retryConfig.maxRetries) {
      try {
        final result = await apiCall();

        // Log success after retry
        if (attemptNumber > 0) {
          developer.log(
            '$operationName succeeded after $attemptNumber retries',
            name: 'ApiClient',
          );
        }

        return result;
      } catch (e) {
        attemptNumber++;

        // If we've exhausted all retries, throw the error
        if (attemptNumber > retryConfig.maxRetries) {
          developer.log(
            '$operationName failed after ${retryConfig.maxRetries} retries: $e',
            name: 'ApiClient',
          );
          rethrow;
        }

        // Calculate delay and wait before retry
        final delay = retryConfig.getDelayForAttempt(attemptNumber);
        developer.log(
          '$operationName failed (attempt $attemptNumber/${retryConfig.maxRetries}), retrying in ${delay.inSeconds}s',
          name: 'ApiClient',
        );
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but added for type safety
    throw Exception('Unexpected retry loop exit');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    RetryConfig? retryConfig,
  }) async {
    return _executeWithRetry(
      () => _dio.get(path, queryParameters: queryParameters),
      retryConfig,
      'GET $path',
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RetryConfig? retryConfig,
  }) async {
    return _executeWithRetry(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
      retryConfig,
      'POST $path',
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    RetryConfig? retryConfig,
  }) async {
    return _executeWithRetry(
      () => _dio.patch(path, data: data),
      retryConfig,
      'PATCH $path',
    );
  }
}
