class HeartbeatData {
  final String status;
  final String userId;

  HeartbeatData({
    required this.status,
    required this.userId,
  });

  factory HeartbeatData.fromJson(Map<String, dynamic> json) {
    return HeartbeatData(
      status: json['status'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'userId': userId,
    };
  }

  bool get isOnline => status == 'online';
}
