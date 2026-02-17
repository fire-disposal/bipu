import 'api.dart';
import '../models/service/service_account.dart';
import '../models/common/paginated_response.dart';

class ServiceAccountApi {
  final ApiClient _api;

  ServiceAccountApi([ApiClient? client]) : _api = client ?? api;

  Future<PaginatedResponse<ServiceAccount>> getServices({
    int page = 1,
    int size = 20,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/service_accounts/',
      queryParameters: {'skip': (page - 1) * size, 'limit': size},
    );
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
    final data = await _api.get<Map<String, dynamic>>(
      '/api/service_accounts/subscriptions/',
      queryParameters: {'skip': (page - 1) * size, 'limit': size},
    );
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
    await _api.post<void>('/api/service_accounts/$serviceName/subscribe');
  }

  Future<void> unsubscribe(String serviceName) async {
    await _api.delete<void>('/api/service_accounts/$serviceName/subscribe');
  }
}
