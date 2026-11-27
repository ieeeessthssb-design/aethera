import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class WeatherApiService {
  WeatherApiService() : _apiClient = ApiClient(TokenStorage.instance);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    final response = await _apiClient.dio.get('/weather/locations', queryParameters: {'q': query});
    final rows = (response.data['results'] as List<dynamic>? ?? []);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> forecast({
    required double latitude,
    required double longitude,
    String timezone = 'auto',
  }) async {
    final response = await _apiClient.dio.get('/weather/forecast', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> forecastForFarm(String farmId) async {
    final response = await _apiClient.dio.get('/weather/farms/$farmId/forecast');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
