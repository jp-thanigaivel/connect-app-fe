import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/models/api_response.dart';
import 'dart:developer' as developer;

class DocumentService {
  final ApiClient _apiClient = ApiClient();
  final Dio _dio =
      Dio(); // Secondary Dio for direct S3 upload (no auth headers)

  Future<ApiResponse<Map<String, dynamic>>> getPresignedUrl({
    required String documentType,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.documentsPresign,
        data: {
          'documentType': documentType,
          'fileName': fileName,
          'contentType': contentType,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } catch (error) {
      developer.log('Error getting presigned URL: $error',
          name: 'DocumentService');
      rethrow;
    }
  }

  Future<void> uploadToS3({
    required String url,
    required Map<String, dynamic> fields,
    required File file,
    required String contentType,
  }) async {
    try {
      final formDataMap = <String, dynamic>{...fields};
      formDataMap['Content-Type'] = contentType;
      formDataMap['file'] = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        url,
        data: formData,
      );

      developer.log('S3 Upload Status: ${response.statusCode}',
          name: 'DocumentService');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to upload file to S3');
      }
    } catch (error) {
      developer.log('Error uploading to S3: $error', name: 'DocumentService');
      rethrow;
    }
  }
}
