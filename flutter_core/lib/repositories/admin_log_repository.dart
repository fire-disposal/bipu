import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/admin_log_model.dart';
import '../models/paginated_response.dart';

class AdminLogRepository {
  final ApiClient _apiClient = ApiClient();

  Future<PaginatedResponse<AdminLog>> getLogs({
    int page = 1,
    int size = 20,
    // Add filtering if needed usually
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminLogs,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => AdminLog.fromJson(json),
    );
  }

  Future<AdminLog> getLog(int id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminLogDetails(id));
    return AdminLog.fromJson(response.data);
  }

  Future<void> deleteLog(int id) async {
    await _apiClient.dio.delete(ApiEndpoints.adminLogDetails(id));
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminLogStats);
    return response.data;
  }
}
