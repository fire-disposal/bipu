import '../core/network/api_client.dart';

class HealthRepository {
  final _client = ApiClient().restClient;

  Future<dynamic> checkHealth() {
    return _client.checkHealth();
  }

  Future<bool> checkReadiness() async {
    try {
      final data = await _client.checkReadiness();
      return data['status'] == 'ready';
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkLiveness() async {
    try {
      final data = await _client.checkLiveness();
      return data['status'] == 'alive';
    } catch (e) {
      return false;
    }
  }
}
