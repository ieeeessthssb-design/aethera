
import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;

          final excludedPaths = [
            '/auth/login',
            '/auth/login-phone',
            '/auth/register',
            '/auth/register-phone',
            '/auth/google',
            '/auth/verify-email',
            '/auth/verify-phone',
            '/auth/resend-verification',
            '/auth/refresh',
            '/auth/logout',
];

          if (error.response?.statusCode != 401 ||
              request.extra['retried'] == true ||
              excludedPaths.contains(request.path)) {
            handler.next(error);
            return;
          }

          try {
            _refreshFuture ??= _performRefresh();
            await _refreshFuture;
            _refreshFuture = null;

            final newToken = await _tokenStorage.getAccessToken();

            if (newToken == null) {
              handler.next(error);
              return;
            }

            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $newToken';

            final response = await dio.fetch(request);
            handler.resolve(response);
          } catch (_) {
            _refreshFuture = null;
            await _tokenStorage.clearTokens();
            handler.next(error);
          }
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  Future<void>? _refreshFuture;

  Future<void> _performRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token available.');
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
      ),
    );

    final response = await refreshDio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final data = Map<String, dynamic>.from(response.data as Map);

    final accessToken = data['access_token'] as String?;
    final newRefreshToken = data['refresh_token'] as String?;

    if (accessToken == null || newRefreshToken == null) {
      throw const FormatException('Invalid refresh response.');
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
    );
  }
}
