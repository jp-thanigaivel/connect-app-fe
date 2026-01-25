import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/core/utils/jwt_utils.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/user_profile.dart';
import 'dart:developer' as developer;

class UserApiService {
  final ApiClient _apiClient = ApiClient();

  Future<UserProfile?> getUserProfile() async {
    try {
      final token = await TokenManager.getAccessToken();
      if (token == null) {
        developer.log('No access token found', name: 'UserApiService');
        return null;
      }

      final userId = JwtUtils.getUserId(token);
      if (userId == null) {
        developer.log('Could not extract userId from token',
            name: 'UserApiService');
        return null;
      }

      developer.log('Fetching profile for userId: $userId',
          name: 'UserApiService');

      final response =
          await _apiClient.get('${ApiConstants.userProfile}/$userId');

      final apiResponse = ApiResponse<UserProfile>.fromJson(
        response.data,
        (json) => UserProfile.fromJson(json),
      );

      if (apiResponse.status.isSuccess) {
        return apiResponse.data;
      } else {
        developer.log(
            'Failed to fetch profile: ${apiResponse.status.statusDesc}',
            name: 'UserApiService');
        return null;
      }
    } catch (e) {
      developer.log('Error fetching user profile: $e', name: 'UserApiService');
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
        developer.log(
            'Failed to update profile: ${apiResponse.status.statusDesc}',
            name: 'UserApiService');
        return null;
      }
    } catch (e) {
      developer.log('Error updating user profile: $e', name: 'UserApiService');
      return null;
    }
  }
}
