import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class HealthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _apiClient.dio.get(ApiEndpoints.health);
    return response.data as Map<String, dynamic>;
  }

  Future<bool> checkReadiness() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.healthReady);
      return response.data['status'] == 'ready';
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkLiveness() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.healthLive);
      return response.data['status'] == 'alive';
    } catch (e) {
      return false;
    }
  }
}
