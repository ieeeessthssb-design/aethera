class ApiConfig {
  ApiConfig._();

  // Override at build time for Docker, staging, or a physical device:
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
