class SupportMessage {
  final String id;
  final String ticketId;
  final String senderType;
  final String senderId;
  final String message;
  final String createdOn;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.createdOn,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['_id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      senderType: json['senderType'] ?? '',
      senderId: json['senderId'] ?? '',
      message: json['message'] ?? '',
      createdOn: json['createdOn'] ?? '',
    );
  }

  bool get isAdmin => senderType.toUpperCase() == 'ADMIN';
}
