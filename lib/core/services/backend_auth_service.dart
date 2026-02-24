import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendAuthService {
  late final String _baseUrl;

  BackendAuthService() {
    _baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  }

  Future<Map<String, dynamic>> firebaseLogin(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/firebase-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Backend request timed out. Server may be waking up — please try again.'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login with backend: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firebaseUid,
    required String name,
    required String state,
    required String city,
    required String language,
    String role = 'farmer',
    String? phone,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'firebase_uid': firebaseUid,
      'name': name,
      'state': state,
      'city': city,
      'language': language,
      'role': role,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (email != null && email.isNotEmpty) body['email'] = email;

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/profile/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Backend request timed out. Please try again.'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
