import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/core/utils/jwt_utils.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/user_profile.dart';
import 'package:connect/core/utils/app_logger.dart';

import 'dart:developer' as developer;

class UserApiService {
  final ApiClient _apiClient = ApiClient();

  Future<UserProfile?> getUserProfile() async {
    try {
      final token = await TokenManager.getAccessToken();
      if (token == null) {
        AppLogger.info('No access token found', name: 'UserApiService');
        return null;
      }

      final userId = JwtUtils.getUserId(token);
      if (userId == null) {
        AppLogger.info('Could not extract userId from token', name: 'UserApiService');
        return null;
      }

      AppLogger.info('Fetching profile for userId: $userId', name: 'UserApiService');

      final response =
          await _apiClient.get('${ApiConstants.userProfile}/$userId');

      final apiResponse = ApiResponse<UserProfile>.fromJson(
        response.data,
        (json) => UserProfile.fromJson(json),
      );

      if (apiResponse.status.isSuccess) {
        return apiResponse.data;
      } else {
        AppLogger.error('Failed to fetch profile: ${apiResponse.status.statusDesc}', name: 'UserApiService');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching user profile: $e', name: 'UserApiService');
      return null;
    }
  }

  Future<UserProfile?> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.userProfile}/$userId',
        data: data,
      );

      final apiResponse = ApiResponse<UserProfile>.fromJson(
        response.data,
        (json) => UserProfile.fromJson(json),
      );

      if (apiResponse.status.isSuccess) {
        return apiResponse.data;
      } else {
        AppLogger.error('Failed to update profile: ${apiResponse.status.statusDesc}', name: 'UserApiService');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error updating user profile: $e', name: 'UserApiService');
      return null;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _apiClient.delete(ApiConstants.deleteAccount);
      AppLogger.info('Account deleted successfully: ${response.statusCode}', name: 'UserApiService');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting account: $e', name: 'UserApiService');
      return false;
    }
  }
}
