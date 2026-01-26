import '../core/network/api_client.dart';
import '../models/admin_log_model.dart';
import '../models/paginated_response.dart';

class AdminLogRepository {
  final _client = ApiClient().restClient;

  Future<PaginatedResponse<AdminLog>> getLogs({int page = 1, int size = 20}) {
    return _client.getAdminLogs(page: page, size: size);
  }

  Future<AdminLog> getLog(int id) {
    return _client.getAdminLog(id);
  }

  Future<void> deleteLog(int id) {
    return _client.deleteAdminLog(id);
  }

  Future<dynamic> getStats() {
    return _client.getAdminLogStats();
  }
}
