import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/admin_log_model.dart';
import '../models/paginated_response.dart';

class AdminLogRepository {
  final ApiClient _apiClient = ApiClient();

  Future<PaginatedResponse<AdminLog>> getLogs({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminLogs,
        queryParameters: {'page': page, 'size': size},
      );

      // Handle case where backend returns a List instead of PaginatedResponse
      if (response.data is List) {
        final list = response.data as List;
        return PaginatedResponse(
          items: list.map((e) => AdminLog.fromJson(e)).toList(),
          total: list.length,
          page: page,
          size: size,
        );
      }

      return PaginatedResponse.fromJson(
        response.data,
        (json) => AdminLog.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
}
