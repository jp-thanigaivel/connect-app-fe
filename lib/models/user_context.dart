class UserContext {
  final String userId;
  final String orgId;
  final String businessUnitId;
  final List<String> userRoles;

  UserContext({
    required this.userId,
    required this.orgId,
    required this.businessUnitId,
    required this.userRoles,
  });

  factory UserContext.fromJwt(Map<String, dynamic> decodedToken) {
    return UserContext(
      userId: decodedToken['userId'] ?? '',
      orgId: decodedToken['orgId'] ?? '',
      businessUnitId: decodedToken['businessUnitId'] ?? '',
      userRoles: List<String>.from(decodedToken['userRoles'] ?? []),
    );
  }

  Map<String, String> toSentryContext() {
    return {
      'userId': userId,
      'orgId': orgId,
      'businessUnitId': businessUnitId,
      'userRoles': userRoles.join(', '),
    };
  }
}
