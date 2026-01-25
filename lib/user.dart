import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class User {
  const User({
    required this.name,
    required this.gender,
    required this.age,
    required this.profilePhoto,
    required this.phoneNumber,
    this.isOnline = false,
    this.interests = const [],
    this.bio = '',
  });

  final String name;

  final String gender;

  final int age;

  final String profilePhoto;

  final String phoneNumber;

  final bool isOnline;

  final List<String> interests;

  final String bio;
}
