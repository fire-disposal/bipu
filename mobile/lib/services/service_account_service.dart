import 'package:get/get.dart';
import 'base_service.dart';
import '../models/service_account_model.dart';

/// 服务号服务 - 处理服务号相关API
class ServiceAccountService extends BaseService {
  static ServiceAccountService get instance => Get.find();

  final serviceAccounts = <ServiceAccountResponse>[].obs;
  final userSubscriptions = <ServiceAccountResponse>[].obs;
  final isLoading = false.obs;
  final RxString error = ''.obs;

  /// 获取所有活跃服务号列表
  Future<ServiceResponse<List<ServiceAccountResponse>>> getServiceAccounts({
    int? skip,
    int? limit,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/service_accounts/',
      query: {
        if (skip != null) 'skip': skip.toString(),
        if (limit != null) 'limit': limit.toString(),
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final accountList = response.data!
          .map(
            (json) =>
                ServiceAccountResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      serviceAccounts.assignAll(accountList);
      return ServiceResponse.success(accountList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取服务号列表失败', ServiceErrorType.unknown),
    );
  }

  /// 获取特定服务号信息
  Future<ServiceResponse<ServiceAccountResponse>> getServiceAccount(
    String serviceName,
  ) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<ServiceAccountResponse>(
      '/api/service_accounts/$serviceName',
      fromJson: (json) => ServiceAccountResponse.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 获取服务号头像
  Future<ServiceResponse<Map<String, dynamic>>> getServiceAccountAvatar(
    String serviceName,
  ) async {
    final response = await get<Map<String, dynamic>>(
      '/api/service_accounts/$serviceName/avatar',
    );

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    }

    return response;
  }

  /// 获取用户订阅的服务号列表
  Future<ServiceResponse<List<ServiceAccountResponse>>>
  getUserSubscriptions() async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/service_accounts/subscriptions',
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final subscriptionList = response.data!
          .map(
            (json) =>
                ServiceAccountResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      userSubscriptions.assignAll(subscriptionList);
      return ServiceResponse.success(subscriptionList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取订阅列表失败', ServiceErrorType.unknown),
    );
  }

  /// 获取特定服务号的订阅设置
  Future<ServiceResponse<Map<String, dynamic>>> getSubscriptionSettings(
    String serviceName,
  ) async {
    final response = await get<Map<String, dynamic>>(
      '/api/service_accounts/$serviceName/settings',
    );

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    }

    return response;
  }

  /// 更新服务号订阅设置
  Future<ServiceResponse<Map<String, dynamic>>> updateSubscriptionSettings({
    required String serviceName,
    required Map<String, dynamic> settings,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await put<Map<String, dynamic>>(
      '/api/service_accounts/$serviceName/settings',
      data: settings,
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      Get.snackbar('成功', '订阅设置更新成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 订阅服务号
  Future<ServiceResponse<Map<String, dynamic>>> subscribeServiceAccount({
    required String serviceName,
    Map<String, dynamic>? settings,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await post<Map<String, dynamic>>(
      '/api/service_accounts/$serviceName/subscribe',
      data: settings,
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      // 刷新订阅列表
      await getUserSubscriptions();
      Get.snackbar('成功', '订阅成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 取消订阅服务号
  Future<ServiceResponse<void>> unsubscribeServiceAccount(
    String serviceName,
  ) async {
    isLoading.value = true;
    error.value = '';

    final response = await delete<void>(
      '/api/service_accounts/$serviceName/unsubscribe',
    );

    isLoading.value = false;

    if (response.success) {
      // 从订阅列表中移除
      userSubscriptions.removeWhere((account) => account.name == serviceName);
      Get.snackbar('成功', '取消订阅成功', duration: const Duration(seconds: 2));
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 检查是否已订阅服务号
  bool isSubscribed(String serviceName) {
    return userSubscriptions.any((account) => account.name == serviceName);
  }

  /// 根据名称查找服务号
  ServiceAccountResponse? findServiceAccountByName(String name) {
    return serviceAccounts.firstWhereOrNull((account) => account.name == name);
  }

  /// 获取订阅统计
  Map<String, int> getSubscriptionStats() {
    return {
      'totalServiceAccounts': serviceAccounts.length,
      'subscribed': userSubscriptions.length,
      'available': serviceAccounts.length - userSubscriptions.length,
    };
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 清空所有数据
  void clearAll() {
    serviceAccounts.clear();
    userSubscriptions.clear();
    error.value = '';
  }

  /// 初始化服务号数据
  Future<void> initialize() async {
    if (serviceAccounts.isEmpty) {
      await getServiceAccounts();
    }
    if (userSubscriptions.isEmpty) {
      await getUserSubscriptions();
    }
  }

  /// 获取活跃服务号
  List<ServiceAccountResponse> get activeServiceAccounts {
    return serviceAccounts.where((account) => account.isActive).toList();
  }

  /// 获取推荐服务号（按创建时间排序，新的优先）
  List<ServiceAccountResponse> get recommendedServiceAccounts {
    return List.from(serviceAccounts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取用户订阅的服务号名称列表
  List<String> get subscribedServiceNames {
    return userSubscriptions.map((account) => account.name).toList();
  }

  /// 获取服务号头像URL
  String? getServiceAccountAvatarUrl(String serviceName) {
    final account = findServiceAccountByName(serviceName);
    return account?.avatarUrl;
  }

  /// 获取服务号描述
  String? getServiceAccountDescription(String serviceName) {
    final account = findServiceAccountByName(serviceName);
    return account?.description;
  }

  /// 批量检查订阅状态
  Map<String, bool> checkSubscriptionStatus(List<String> serviceNames) {
    final result = <String, bool>{};
    for (final name in serviceNames) {
      result[name] = isSubscribed(name);
    }
    return result;
  }
}
