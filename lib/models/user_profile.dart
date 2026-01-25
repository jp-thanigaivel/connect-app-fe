class UserProfile {
  final String createdOn;
  final String updatedOn;
  final String createdBy;
  final String updatedBy;
  final String displayName;
  final UserName userName;
  final String email;
  final String photoUrl;
  final String userType;
  final String userId;
  final String authProvider;
  final String authProviderId;
  final String isActive;
  final List<String> userRoles;
  final String? dob;
  final String? gender;

  UserProfile({
    required this.createdOn,
    required this.updatedOn,
    required this.createdBy,
    required this.updatedBy,
    required this.displayName,
    required this.userName,
    required this.email,
    required this.photoUrl,
    required this.userType,
    required this.userId,
    required this.authProvider,
    required this.authProviderId,
    required this.isActive,
    required this.userRoles,
    this.dob,
    this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      createdOn: json['createdOn'] ?? '',
      updatedOn: json['updatedOn'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      displayName: json['displayName'] ?? '',
      userName: UserName.fromJson(json['userName'] ?? {}),
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      userType: json['userType'] ?? '',
      userId: json['userId'] ?? '',
      authProvider: json['authProvider'] ?? '',
      authProviderId: json['authProviderId'] ?? '',
      isActive: json['isActive'] ?? '',
      userRoles: List<String>.from(json['userRoles'] ?? []),
      dob: json['dob'],
      gender: json['gender'],
    );
  }
}

class UserName {
  final String firstName;
  final String? middleName;
  final String lastName;

  UserName({
    required this.firstName,
    this.middleName,
    required this.lastName,
  });

  factory UserName.fromJson(Map<String, dynamic> json) {
    return UserName(
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
    );
  }

  String get fullName =>
      '$firstName ${middleName != null ? '$middleName ' : ''}$lastName';
}
