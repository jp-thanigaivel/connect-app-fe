import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse(
      'https://backend.iwoodtechnologies.com/connect/app/api/v1/promotion');
  print('Testing Promotion API: $url');

  try {
    final response = await http.get(url);
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('Parsed JSON successfully');
      print('Data: ${json['data']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
