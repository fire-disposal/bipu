import 'package:dio/dio.dart';
import '../models/common/paginated_response.dart';

// Unified API Service
class ApiService {
  final Dio _dio;
  // ignore: unused_field
  final String baseUrl;

  ApiService(this._dio, {required this.baseUrl});

  // Helper method for pagination
  Future<PaginatedResponse<T>> fetchPaginated<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return PaginatedResponse.fromJson(
      response.data,
      (json) => fromJson(json as Map<String, dynamic>),
    );
  }
}
