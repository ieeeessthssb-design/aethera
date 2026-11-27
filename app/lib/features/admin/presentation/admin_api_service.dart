import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class AdminApiService {
  AdminApiService() : _client = ApiClient(TokenStorage.instance);

  final ApiClient _client;

  Future<Map<String, dynamic>> overview() async {
    final response = await _client.dio.get('/admin/overview');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> pendingExperts() async {
    final response = await _client.dio.get('/admin/experts/pending');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> users() async {
    final response = await _client.dio.get('/admin/users');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _client.dio.patch(
      '/admin/users/$userId/status',
      data: {'is_active': isActive},
    );
  }

  Future<void> decideExpert(String userId, {required bool approve}) async {
    await _client.dio.patch(
      '/admin/experts/$userId/${approve ? 'approve' : 'reject'}',
    );
  }
}
