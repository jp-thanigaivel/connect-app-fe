class SupportTicket {
  final String id;
  final String category;
  final String description;
  final SupportReference reference;
  final String status;
  final String createdOn;
  final String ticketId;

  SupportTicket({
    required this.id,
    required this.category,
    required this.description,
    required this.reference,
    required this.status,
    required this.createdOn,
    required this.ticketId,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      reference: SupportReference.fromJson(json['reference'] ?? {}),
      status: json['status'] ?? 'OPEN',
      createdOn: json['createdOn'] ?? '',
      ticketId: json['ticketId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'category': category,
      'description': description,
      'reference': reference.toJson(),
    };
    return data;
  }
}

class SupportReference {
  final String type;
  final String id;

  SupportReference({
    required this.type,
    required this.id,
  });

  factory SupportReference.fromJson(Map<String, dynamic> json) {
    return SupportReference(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
    };
  }
}
