import 'package:connect/models/auth_response.dart';
import 'package:connect/models/zego_token_response.dart';
import 'package:connect/models/heartbeat_response.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/config/retry_config.dart';
import 'dart:developer' as developer;

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponse> loginWithGoogle(String idToken) async {
    // if (kDebugMode) {
    //   debugPrint('Login with Google: $idToken');
    // }

    try {
      final response = await _apiClient.post(
        ApiConstants.googleSignIn,
        data: {'idToken': idToken},
      );

      developer.log('Backend response status: ${response.statusCode}',
          name: 'AuthApiService');

      final Map<String, dynamic> data = response.data;
      final authResponse = AuthResponse.fromJson(data);

      if (response.statusCode == 200 && authResponse.status.isSuccess) {
        if (authResponse.data != null) {
          await TokenManager.saveTokens(
            authResponse.data!.accessToken,
            authResponse.data!.refreshToken,
          );
          await TokenManager.saveZegoCredentials(
            authResponse.data!.zegoToken,
            authResponse.data!.zegoAppId,
          );
        }
        return authResponse;
      } else {
        final errorMsg = authResponse.status.statusDesc.isNotEmpty
            ? authResponse.status.statusDesc
            : 'Technical exception occurred (Status: ${response.statusCode})';
        throw Exception(errorMsg);
      }
    } catch (error) {
      developer.log('Error during backend login: $error',
          name: 'AuthApiService');
      rethrow;
    }
  }

  Future<AuthResponse> adminLogin(String phoneNumber, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.adminLogin,
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );

      developer.log('Admin login response status: ${response.statusCode}',
          name: 'AuthApiService');

      final Map<String, dynamic> data = response.data;
      final authResponse = AuthResponse.fromJson(data);

      if (response.statusCode == 200 && authResponse.status.isSuccess) {
        if (authResponse.data != null) {
          await TokenManager.saveTokens(
            authResponse.data!.accessToken,
            authResponse.data!.refreshToken,
          );
          await TokenManager.saveZegoCredentials(
            authResponse.data!.zegoToken,
            authResponse.data!.zegoAppId,
          );
        }
        return authResponse;
      } else {
        throw Exception(authResponse.status.statusDesc.isNotEmpty
            ? authResponse.status.statusDesc
            : 'Admin login failed');
      }
    } catch (error) {
      developer.log('Error during admin login: $error', name: 'AuthApiService');
      rethrow;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await TokenManager.saveTokens(accessToken, refreshToken);
  }

  Future<ZegoTokenResponse> refreshZegoToken() async {
    try {
      final response = await _apiClient.post(ApiConstants.zegoTokenRefresh);

      developer.log('Zego token refresh status: ${response.statusCode}',
          name: 'AuthApiService');
      // if (kDebugMode) {
      //   debugPrint('Zego token refresh status: ${response.statusCode}');
      // }

      final zegoResponse = ZegoTokenResponse.fromJson(response.data);

      if (response.statusCode == 200 && zegoResponse.status.isSuccess) {
        if (zegoResponse.data != null) {
          await TokenManager.saveZegoCredentials(
            zegoResponse.data!.zegoToken,
            zegoResponse.data!.zegoAppId.toString(),
          );
        }
        return zegoResponse;
      } else {
        throw Exception(zegoResponse.status.statusDesc);
      }
    } catch (error) {
      developer.log('Error refreshing Zego token: $error',
          name: 'AuthApiService');
      rethrow;
    }
  }

  Future<void> refreshToken() async {
    // Implementation for refreshing the access token
  }

  /// Sends heartbeat to the server with optional status
  ///
  /// Uses [RetryConfig.standard] for automatic retries on failure.
  /// Pass [retryConfig] to customize retry behavior or use [RetryConfig.none] to disable retries.
  Future<ApiResponse<HeartbeatData>> sendHeartbeat({
    String? status,
    RetryConfig? retryConfig,
  }) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      final response = await _apiClient.post(
        ApiConstants.heartbeat,
        queryParameters: queryParams,
        retryConfig: retryConfig ?? RetryConfig.standard,
      );

      developer.log(
          'Heartbeat status: ${response.statusCode}${status != null ? ' (status: $status)' : ''}',
          name: 'AuthApiService');

      final apiResponse = ApiResponse<HeartbeatData>.fromJson(
        response.data,
        (json) => HeartbeatData.fromJson(json as Map<String, dynamic>),
      );

      return apiResponse;
    } catch (error) {
      developer.log('Error sending heartbeat: $error', name: 'AuthApiService');
      rethrow;
    }
  }
}
