class AuthResponse {
  final AuthStatus status;
  final AuthData? data;

  AuthResponse({
    required this.status,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: AuthStatus.fromJson(json['status']),
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }
}

class AuthStatus {
  final String statusCode;
  final String statusType;
  final String statusDesc;

  AuthStatus({
    required this.statusCode,
    required this.statusType,
    required this.statusDesc,
  });

  factory AuthStatus.fromJson(Map<String, dynamic> json) {
    return AuthStatus(
      statusCode: (json['statusCode'] ?? json['errorCode'])?.toString() ?? '',
      statusType: json['statusType'] ?? '',
      statusDesc: json['statusDesc'] ?? '',
    );
  }

  bool get isSuccess => statusCode == '200' && statusType == 'SUCCESS';
}

class AuthData {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String zegoToken;
  final String zegoAppId;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.zegoToken,
    required this.zegoAppId,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      zegoToken: json['zegoToken'] ?? '',
      zegoAppId: json['zegoAppId']?.toString() ?? '',
    );
  }
}
