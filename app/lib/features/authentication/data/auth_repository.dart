
import 'auth_api_service.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final AuthApiService _apiService;

  Future<Map<String, dynamic>> getProfile() {
    return _apiService.getProfile();
  }

  Future<void> logout() {
    return _apiService.logout();
  }
}
