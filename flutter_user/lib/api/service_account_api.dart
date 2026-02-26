import 'package:dio/dio.dart';
import 'package:flutter_user/models/service/service_account.dart';
import 'package:flutter_user/models/service/subscription_settings.dart';
import 'package:flutter_user/models/common/paginated_response.dart';

class ServiceAccountApi {
  final Dio _dio;

  ServiceAccountApi(this._dio);

  Future<PaginatedResponse<ServiceAccount>> getServices({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/service_accounts/',
      queryParameters: {'page': page, 'page_size': size},
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => ServiceAccount.fromJson(e))
        .toList();

    return PaginatedResponse<ServiceAccount>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['page_size'] as int,
    );
  }

  Future<ServiceAccount> getServiceByName(String name) async {
    final response = await _dio.get('/api/service_accounts/$name');
    return ServiceAccount.fromJson(response.data);
  }

  Future<List<ServiceAccount>> getActiveServices() async {
    final response = await _dio.get('/api/service_accounts/active');
    final data = response.data as List<dynamic>;
    return data.map((e) => ServiceAccount.fromJson(e)).toList();
  }

  Future<List<SubscriptionSettings>> getUserSubscriptions() async {
    final response = await _dio.get('/api/service_accounts/subscriptions/');
    final data = response.data as List<dynamic>;
    return data.map((e) => SubscriptionSettings.fromJson(e)).toList();
  }

  Future<SubscriptionSettings> getServiceSettings(String name) async {
    final response = await _dio.get('/api/service_accounts/$name/settings');
    return SubscriptionSettings.fromJson(response.data);
  }

  Future<SubscriptionSettings> updateServiceSettings(
    String name,
    SubscriptionSettings body,
  ) async {
    final response = await _dio.put(
      '/api/service_accounts/$name/settings',
      data: body.toJson(),
    );
    return SubscriptionSettings.fromJson(response.data);
  }

  Future<void> subscribe(String serviceName) async {
    await _dio.post('/api/service_accounts/$serviceName/subscribe');
  }

  Future<void> unsubscribe(String serviceName) async {
    await _dio.delete('/api/service_accounts/$serviceName/subscribe');
  }

  Future<String> getServiceAvatar(String name) async {
    final response = await _dio.get('/api/service_accounts/$name/avatar');
    final data = response.data as Map<String, dynamic>;
    return data['avatar_url'] as String? ?? '';
  }

  Future<List<ServiceAccount>> searchServices(String query) async {
    final response = await _dio.get(
      '/api/service_accounts/search',
      queryParameters: {'q': query, 'limit': 20},
    );
    final data = response.data as List<dynamic>;
    return data.map((e) => ServiceAccount.fromJson(e)).toList();
  }

  Future<bool> checkService(String bipupuId) async {
    try {
      final response = await _dio.get('/api/service_accounts/check/$bipupuId');
      final data = response.data as Map<String, dynamic>;
      return data['exists'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isSubscribed(String serviceName) async {
    try {
      final response = await _dio.get(
        '/api/service_accounts/$serviceName/subscribed',
      );
      final data = response.data as Map<String, dynamic>;
      return data['subscribed'] == true;
    } catch (_) {
      return false;
    }
  }
}
