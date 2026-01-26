import 'package:connect/core/api/api_client.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/models/api_response.dart';
import 'package:connect/models/support_ticket.dart';
import 'package:connect/models/support_message.dart';
import 'dart:developer' as developer;

class SupportApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<SupportTicket>>> getSupportTickets(
      {String? nextCursor}) async {
    try {
      final queryParams =
          nextCursor != null ? {'nextCursor': nextCursor} : null;
      final response = await _apiClient.get(
        ApiConstants.supportTickets,
        queryParameters: queryParams,
      );

      return ApiResponse<List<SupportTicket>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => SupportTicket.fromJson(e)).toList(),
      );
    } catch (e) {
      developer.log('Error fetching support tickets: $e',
          name: 'SupportApiService');
      rethrow;
    }
  }

  Future<ApiResponse<SupportTicket>> createSupportTicket(
      SupportTicket ticket) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.supportTickets,
        data: ticket.toJson(),
      );

      return ApiResponse<SupportTicket>.fromJson(
        response.data,
        (json) => SupportTicket.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      developer.log('Error creating support ticket: $e',
          name: 'SupportApiService');
      rethrow;
    }
  }

  Future<ApiResponse<List<SupportMessage>>> getTicketMessages(
      String ticketId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.supportTickets}/$ticketId/messages',
      );

      return ApiResponse<List<SupportMessage>>.fromJson(
        response.data,
        (json) =>
            (json as List).map((e) => SupportMessage.fromJson(e)).toList(),
      );
    } catch (e) {
      developer.log('Error fetching ticket messages: $e',
          name: 'SupportApiService');
      rethrow;
    }
  }

  Future<ApiResponse<SupportMessage>> sendTicketMessage(
      String ticketId, String message) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.supportTickets}/$ticketId/messages',
        data: {'message': message},
      );

      return ApiResponse<SupportMessage>.fromJson(
        response.data,
        (json) => SupportMessage.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      developer.log('Error sending ticket message: $e',
          name: 'SupportApiService');
      rethrow;
    }
  }
}
