class ZegoTokenResponse {
  final ZegoTokenStatus status;
  final ZegoTokenData? data;

  ZegoTokenResponse({
    required this.status,
    this.data,
  });

  factory ZegoTokenResponse.fromJson(Map<String, dynamic> json) {
    return ZegoTokenResponse(
      status: ZegoTokenStatus.fromJson(json['status']),
      data: json['data'] != null ? ZegoTokenData.fromJson(json['data']) : null,
    );
  }
}

class ZegoTokenStatus {
  final String statusCode;
  final String statusType;
  final String statusDesc;

  ZegoTokenStatus({
    required this.statusCode,
    required this.statusType,
    required this.statusDesc,
  });

  factory ZegoTokenStatus.fromJson(Map<String, dynamic> json) {
    return ZegoTokenStatus(
      statusCode: json['statusCode'] ?? '',
      statusType: json['statusType'] ?? '',
      statusDesc: json['statusDesc'] ?? '',
    );
  }

  bool get isSuccess => statusCode == '200' && statusType == 'SUCCESS';
}

class ZegoTokenData {
  final String zegoToken;
  final dynamic zegoAppId; // Can be int or string, safe to handle both

  ZegoTokenData({
    required this.zegoToken,
    required this.zegoAppId,
  });

  factory ZegoTokenData.fromJson(Map<String, dynamic> json) {
    return ZegoTokenData(
      zegoToken: json['zegoToken'] ?? '',
      zegoAppId: json['zegoAppId'],
    );
  }
}
