import 'api.dart';
import '../models/common/paginated_response.dart';

// Unified API Service
class ApiService {
  final ApiClient _api;
  // ignore: unused_field
  final String baseUrl;

  ApiService(this._api, {required this.baseUrl});

  // Helper method for pagination
  Future<PaginatedResponse<T>> fetchPaginated<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return PaginatedResponse.fromJson(
      data,
      (json) => fromJson(json as Map<String, dynamic>),
    );
  }
}
