import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'failover_http_client.dart';

class BackendAuthService {
  static final _client = FailoverHttpClient(
    primaryUrl: AppConstants.backendPrimaryUrl,
    fallbackUrl: AppConstants.backendFallbackUrl,
    timeout: const Duration(seconds: 20),
  );

  Future<Map<String, dynamic>> firebaseLogin(String token) async {
    final response = await _client.post(
      '/auth/firebase-login',
      body: {'token': token},
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

    final response = await _client.post(
      '/auth/profile/update',
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
