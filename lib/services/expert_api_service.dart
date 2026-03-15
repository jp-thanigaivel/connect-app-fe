import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/expert.dart';
import 'dart:developer' as developer;

import 'package:connect/models/search_config.dart';
import 'package:connect/core/utils/app_logger.dart';


class ExpertApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Expert>>> getExperts({
    String? nextCursor,
    Map<String, dynamic>? filters,
    List<String>? sort,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (nextCursor != null) {
        queryParams['nextCursor'] = nextCursor;
      }

      if (filters != null) {
        filters.forEach((key, value) {
          if (value is List) {
            if (value.isNotEmpty) {
              queryParams[key] = value.join(',');
            }
          } else if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort.join(',');
      }

      final response = await _apiClient.get(
        ApiConstants.experts,
        queryParameters: queryParams,
      );

      AppLogger.info('Fetch experts response: ${response.statusCode}', name: 'ExpertApiService');

      return ApiResponse.fromJson(
        response.data,
        (json) => (json as List).map((e) => Expert.fromJson(e)).toList(),
      );
    } catch (error) {
      AppLogger.error('Error fetching experts: $error', name: 'ExpertApiService');
      rethrow;
    }
  }

  Future<ApiResponse<SearchConfig>> getSearchConfig() async {
    try {
      final response = await _apiClient.get(ApiConstants.searchConfig);
      AppLogger.info('Fetch search config response: ${response.statusCode}', name: 'ExpertApiService');
      return ApiResponse.fromJson(
        response.data,
        (json) => SearchConfig.fromJson(json),
      );
    } catch (error) {
      AppLogger.error('Error fetching search config: $error', name: 'ExpertApiService');
      rethrow;
    }
  }

  Future<ApiResponse<Expert>> getExpertByUserId(String userId) async {
    try {
      final response =
          await _apiClient.get('${ApiConstants.expertByUserId}/$userId');
      AppLogger.info('Fetch expert by userId response: ${response.statusCode}', name: 'ExpertApiService');
      return ApiResponse.fromJson(
        response.data,
        (json) => Expert.fromJson(json),
      );
    } catch (error) {
      AppLogger.error('Error fetching expert by userId: $error', name: 'ExpertApiService');
      rethrow;
    }
  }

  Future<ApiResponse<Expert>> updateExpert(
      String expertId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.experts}/$expertId',
        data: data,
      );
      AppLogger.info('Update expert response: ${response.statusCode}', name: 'ExpertApiService');
      return ApiResponse.fromJson(
        response.data,
        (json) => Expert.fromJson(json),
      );
    } catch (error) {
      AppLogger.error('Error updating expert: $error', name: 'ExpertApiService');
      rethrow;
    }
  }

  Future<ApiResponse<List<AllowedValue>>> getAvailableLanguages() async {
    try {
      final response = await _apiClient.get(ApiConstants.expertLanguages);
      AppLogger.info('Fetch available languages response: ${response.statusCode}', name: 'ExpertApiService');
      return ApiResponse.fromJson(
        response.data,
        (json) => (json as List).map((e) => AllowedValue.fromJson(e)).toList(),
      );
    } catch (error) {
      AppLogger.error('Error fetching available languages: $error', name: 'ExpertApiService');
      rethrow;
    }
  }

  Future<ApiResponse<List<AllowedValue>>> getAvailableExpertiseTags() async {
    try {
      final response = await _apiClient.get(ApiConstants.expertExpertiseTags);
      AppLogger.info('Fetch available expertise tags response: ${response.statusCode}', name: 'ExpertApiService');
      return ApiResponse.fromJson(
        response.data,
        (json) => (json as List).map((e) => AllowedValue.fromJson(e)).toList(),
      );
    } catch (error) {
      AppLogger.error('Error fetching available expertise tags: $error', name: 'ExpertApiService');
      rethrow;
    }
  }
}
