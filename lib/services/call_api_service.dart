import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/core/config/retry_config.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/call_session.dart';
import 'dart:developer' as developer;

class CallApiService {
  final ApiClient _apiClient = ApiClient();

  Future<String?> initiateCall(String calleeId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.initiateCall,
        data: {
          'calleeId': calleeId,
        },
      );

      developer.log('Initiate call response: ${response.statusCode}',
          name: 'CallApiService');

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json, // data is the map itself containing callSessionId
      );

      if (apiResponse.status.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data as Map<String, dynamic>;
        return data['callSessionId'] as String?;
      }
      return null;
    } catch (error) {
      developer.log('Error initiating call: $error', name: 'CallApiService');
      rethrow;
    }
  }

  /// Sends call heartbeat to the server
  ///
  /// Uses [RetryConfig.standard] for automatic retries on failure.
  /// Pass [retryConfig] to customize retry behavior or use [RetryConfig.none] to disable retries.
  Future<void> sendHeartbeat(
    String callSessionId, {
    RetryConfig? retryConfig,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.callHeartbeat,
        data: {
          'callSessionId': callSessionId,
        },
        retryConfig: retryConfig ?? RetryConfig.standard,
      );
      developer.log('Heartbeat sent: ${response.statusCode}',
          name: 'CallApiService');
    } catch (error) {
      // Log but don't rethrow to avoid crashing the heartbeat loop
      developer.log('Error sending heartbeat: $error', name: 'CallApiService');
    }
  }

  Future<List<CallSession>> getCallHistory() async {
    try {
      final response = await _apiClient.get(ApiConstants.callHistory);

      developer.log('Get call history response: ${response.statusCode}',
          name: 'CallApiService');

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) {
          return (json as List).map((e) => CallSession.fromJson(e)).toList();
        },
      );

      return apiResponse.data ?? [];
    } catch (error) {
      developer.log('Error fetching call history: $error',
          name: 'CallApiService');
      rethrow;
    }
  }
}
