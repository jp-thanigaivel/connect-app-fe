import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/promotion.dart';
import 'dart:developer' as developer;

class PromotionApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Promotion>>> getPromotions() async {
    try {
      final response = await _apiClient.get(ApiConstants.promotion);

      if (response.data == null) {
        return ApiResponse(
          status: ApiStatus(
              statusCode: '404', statusType: 'ERROR', statusDesc: 'No content'),
        );
      }

      final rootJson = response.data as Map<String, dynamic>;
      final innerData = rootJson['data'] as Map<String, dynamic>?;

      if (innerData == null) {}

      final promotions = <Promotion>[];
      if (innerData != null && innerData['data'] != null) {
        for (var item in (innerData['data'] as List)) {
          try {
            promotions.add(Promotion.fromJson(item));
          } catch (itemError) {}
        }
      }

      return ApiResponse<List<Promotion>>(
        status: ApiStatus.fromJson(rootJson['status'] ?? {}),
        data: promotions,
        pagination: innerData != null && innerData['pagination'] != null
            ? ApiPagination.fromJson(innerData['pagination'])
            : null,
      );
    } catch (e) {
      return ApiResponse(
        status: ApiStatus(
          statusCode: '500',
          statusType: 'ERROR',
          statusDesc: 'Failed to fetch promotions: $e',
        ),
      );
    }
  }
}
