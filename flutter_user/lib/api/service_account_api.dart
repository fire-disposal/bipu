import 'api.dart';
import '../models/service/service_account.dart';
import '../models/service/subscription_settings.dart';
import '../models/common/paginated_response.dart';

class ServiceAccountApi {
  final ApiClient _api;

  ServiceAccountApi([ApiClient? client]) : _api = client ?? api;

  Future<SubscriptionSettings> getSubscriptionSettings(
    String serviceName,
  ) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/service_accounts/$serviceName/settings',
    );
    return SubscriptionSettings.fromJson(data);
  }

  Future<SubscriptionSettings> updateSubscriptionSettings(
    String serviceName,
    SubscriptionSettings settings,
  ) async {
    final data = await _api.put<Map<String, dynamic>>(
      '/api/service_accounts/$serviceName/settings',
      data: settings.toUpdateJson(),
    );
    return SubscriptionSettings.fromJson(data);
  }

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

    // 处理新的响应格式
    if (data.containsKey('subscriptions')) {
      final subscriptions = (data['subscriptions'] as List).map((e) {
        // 从订阅响应中提取服务号信息
        if (e is Map<String, dynamic>) {
          if (e.containsKey('service')) {
            return ServiceAccount.fromJson(e['service']);
          }
        }
        return ServiceAccount.fromJson(e);
      }).toList();

      return PaginatedResponse(
        items: subscriptions,
        total: data['total'] ?? subscriptions.length,
        page: page,
        size: size,
        pages: ((data['total'] ?? subscriptions.length) / size).ceil(),
      );
    }

    // 兼容旧的响应格式
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

  Future<void> subscribe(
    String serviceName, {
    SubscriptionSettings? initialSettings,
  }) async {
    final Map<String, dynamic>? data;
    if (initialSettings != null) {
      data = initialSettings.toUpdateJson();
    } else {
      data = null;
    }

    await _api.post<void>(
      '/api/service_accounts/$serviceName/subscribe',
      data: data,
    );
  }

  Future<void> unsubscribe(String serviceName) async {
    await _api.delete<void>('/api/service_accounts/$serviceName/subscribe');
  }
}
