import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FastApiAuthException implements Exception {
  final String message;
  const FastApiAuthException(this.message);

  @override
  String toString() => message;
}

class FastApiAuthService {
  static const String _baseUrl = String.fromEnvironment(
    'AETHERA_API_URL',
    defaultValue: 'http://localhost:8001',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessKey = 'aethera_fastapi_access';
  static const String _refreshKey = 'aethera_fastapi_refresh';
  static const String _expiryKey = 'aethera_fastapi_expiry';

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      return {};
    }
  }

  static String _errorMessage(http.Response response) {
    final data = _decode(response);
    return data['detail']?.toString() ??
        'FastAPI request failed (${response.statusCode}).';
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final access = data['access_token']?.toString();
    final refresh = data['refresh_token']?.toString();
    final expiresIn = data['expires_in'];

    if (access == null || access.isEmpty ||
        refresh == null || refresh.isEmpty) {
      throw const FastApiAuthException(
        'FastAPI returned an incomplete authentication response.',
      );
    }

    final seconds = expiresIn is num ? expiresIn.toInt() : 900;
    final expiry = DateTime.now()
        .add(Duration(seconds: seconds))
        .millisecondsSinceEpoch;

    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _expiryKey, value: expiry.toString());
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw FastApiAuthException(_errorMessage(response));
    }

    await _saveSession(_decode(response));
  }

  static Future<String?> getAccessToken() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final expiryText = await _storage.read(key: _expiryKey);

    if (access == null || refresh == null) return null;

    final expiry = int.tryParse(expiryText ?? '');

    if (expiry != null &&
        DateTime.now().millisecondsSinceEpoch < expiry - 60000) {
      return access;
    }

    return await _refreshSession(refresh);
  }

  static Future<String?> _refreshSession(String refresh) async {
    try {
      final response = await http
          .post(
            _uri('/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        await clearSession();
        return null;
      }

      final data = _decode(response);
      await _saveSession(data);
      return data['access_token']?.toString();
    } catch (_) {
      // Keep the existing session if the server is temporarily unreachable.
      rethrow;
    }
  }

  static Future<void> logout() async {
    final refresh = await _storage.read(key: _refreshKey);

    try {
      if (refresh != null) {
        await http
            .post(
              _uri('/auth/logout'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': refresh}),
            )
            .timeout(const Duration(seconds: 10));
      }
    } finally {
      await clearSession();
    }
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiryKey);
  }
}
