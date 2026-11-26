
import '../../../core/network/api_client.dart';

class IrrigationApiService {
  IrrigationApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createDevice({required String farmId, required String name, required bool isSimulated}) async {
    final response = await _apiClient.dio.post(
      '/farms/$farmId/devices',
      data: {'name': name, 'is_simulated': isSimulated},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getDevices(
    String farmId,
  ) async {
    final response = await _apiClient.dio.get(
      '/farms/$farmId/devices',
    );

    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> getLatestReading({
    required String farmId,
    required String deviceId,
  }) async {
    final response = await _apiClient.dio.get(
      '/farms/$farmId/devices/$deviceId/readings/latest',
    );

    if (response.data == null) return null;

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getReadingHistory({
    required String farmId,
    required String deviceId,
    int limit = 50,
  }) async {
    final response = await _apiClient.dio.get(
      '/farms/$farmId/devices/$deviceId/readings',
      queryParameters: {'limit': limit},
    );

    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getFarmAlerts(String farmId) async {
    final response = await _apiClient.dio.get('/farms/$farmId/alerts');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> acknowledgeFarmAlert({
    required String farmId,
    required String alertId,
  }) async {
    await _apiClient.dio.patch('/farms/$farmId/alerts/$alertId/acknowledge');
  }

  Future<void> deactivateDevice({
    required String farmId,
    required String deviceId,
  }) async {
    await _apiClient.dio.patch(
      '/farms/$farmId/devices/$deviceId/deactivate',
    );
  }
}
