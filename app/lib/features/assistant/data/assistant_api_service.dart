import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class AssistantApiService {
  AssistantApiService() : _client = ApiClient(TokenStorage.instance);

  final ApiClient _client;

  Future<Map<String, dynamic>> ask({
    required String farmId,
    required String message,
  }) async {
    final response = await _client.dio.post(
      '/assistant/chat',
      data: {'farm_id': farmId, 'message': message},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
