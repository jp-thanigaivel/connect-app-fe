import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic> decode(String token) {
    final splitToken = token.split(".");
    if (splitToken.length != 3) {
      throw const FormatException('Invalid token');
    }
    final payloadBase64 = splitToken[1];
    final normalizedPayload = base64.normalize(payloadBase64);
    final payloadString = utf8.decode(base64.decode(normalizedPayload));
    final decodedPayload = jsonDecode(payloadString);

    return decodedPayload;
  }

  static String? getUserId(String token) {
    try {
      final decoded = decode(token);
      return decoded['userId'] as String?;
    } catch (e) {
      return null;
    }
  }
}
