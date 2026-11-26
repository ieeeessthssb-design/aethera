
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class AuthApiService {
  AuthApiService(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // EMAIL REGISTRATION
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String preferredLanguage,
    required String role,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/register',
      data: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'preferred_language': preferredLanguage,
        'role': role,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  // EMAIL VERIFICATION
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/verify-email',
      data: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );

    return _handleAuthResponse(response);
  }

  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/resend-verification',
      data: {'email': email.trim()},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  // EMAIL LOGIN
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    return _handleAuthResponse(response);
  }

  // GOOGLE LOGIN
  // Assumes the backend verifies Firebase ID tokens at /auth/google.

  // GOOGLE SIGN-IN
  Future<Map<String, dynamic>> signInWithGoogle({
    required String idToken,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/google',
      data: {
        'id_token': idToken,
      },
    );

    return _handleAuthResponse(response);
  }


  // PHONE REGISTRATION - retained for backend compatibility
  Future<Map<String, dynamic>> signUpPhone({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String preferredLanguage,
    required String role,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/register-phone',
      data: {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'preferred_language': preferredLanguage,
        'role': role,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> verifyPhone({
    required String phoneNumber,
    required String firebaseIdToken,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/verify-phone',
      data: {
        'phone_number': phoneNumber.trim(),
        'firebase_id_token': firebaseIdToken,
      },
    );

    return _handleAuthResponse(response);
  }

  Future<Map<String, dynamic>> signInPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/login-phone',
      data: {
        'phone_number': phoneNumber.trim(),
        'password': password,
      },
    );

    return _handleAuthResponse(response);
  }

  // CURRENT USER
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.dio.get('/auth/me');

    return Map<String, dynamic>.from(response.data as Map);
  }

  // SAVE AUTHENTICATION TOKENS
  Future<Map<String, dynamic>> _handleAuthResponse(
    Response<dynamic> response,
  ) async {
    final data = Map<String, dynamic>.from(response.data as Map);

    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw const FormatException(
        'The authentication response did not contain both tokens.',
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return data;
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      await _apiClient.dio.post(
        '/auth/logout',
        data: {
          'refresh_token': refreshToken,
        },
      );
    } on DioException {
      // Clear local credentials even if the server is unavailable.
    } finally {
      await _tokenStorage.clearTokens();
    }
  }
}
