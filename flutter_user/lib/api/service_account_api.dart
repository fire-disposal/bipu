import 'package:dio/dio.dart';
import '../models/service/service_account.dart';
import '../models/common/paginated_response.dart';

class ServiceAccountApi {
  final Dio _dio;

  ServiceAccountApi(this._dio);

  Future<PaginatedResponse<ServiceAccount>> getServices({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/service_accounts/',
      queryParameters: {'skip': (page - 1) * size, 'limit': size},
    );
    final data = response.data;
    return PaginatedResponse(
      items: (data['items'] as List)
          .map((e) => ServiceAccount.fromJson(e))
          .toList(),
      total: data['total'],
      page: page,
      size: size,
      pages: (data['total'] / size).ceil(),
    );
  }

  Future<PaginatedResponse<ServiceAccount>> getUserSubscriptions({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/service_accounts/subscriptions/',
      queryParameters: {'skip': (page - 1) * size, 'limit': size},
    );
    final data = response.data;
    return PaginatedResponse(
      items: (data['items'] as List)
          .map((e) => ServiceAccount.fromJson(e))
          .toList(),
      total: data['total'],
      page: page,
      size: size,
      pages: (data['total'] / size).ceil(),
    );
  }

  Future<void> subscribe(String serviceName) async {
    await _dio.post('/api/service_accounts/$serviceName/subscribe');
  }

  Future<void> unsubscribe(String serviceName) async {
    await _dio.delete('/api/service_accounts/$serviceName/subscribe');
  }
}
