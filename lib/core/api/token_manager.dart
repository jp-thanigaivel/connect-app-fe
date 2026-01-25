import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _zegoTokenKey = 'zego_token';
  static const String _zegoAppIdKey = 'zego_app_id';
  static const String _userTypeKey = 'user_type';

  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> saveZegoCredentials(
      String zegoToken, String zegoAppId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zegoTokenKey, zegoToken);
    await prefs.setString(_zegoAppIdKey, zegoAppId);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> getZegoToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_zegoTokenKey);
  }

  static Future<String?> getZegoAppId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_zegoAppIdKey);
  }

  static Future<void> saveUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType);
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_zegoTokenKey);
    await prefs.remove(_zegoAppIdKey);
    await prefs.remove(_userTypeKey);
  }
}
