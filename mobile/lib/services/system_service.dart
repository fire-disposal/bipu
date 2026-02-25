import 'package:get/get.dart';
import 'base_service.dart';
import '../models/system_model.dart';

/// 系统服务 - 处理健康检查、就绪检查等系统API
class SystemService extends BaseService {
  static SystemService get instance => Get.find();

  final RxBool isHealthy = false.obs;
  final RxBool isReady = false.obs;
  final RxBool isLive = false.obs;
  final Rx<ApiInfoResponse?> apiInfo = Rx<ApiInfoResponse?>(null);
  final RxString error = ''.obs;

  /// 健康检查
  Future<ServiceResponse<HealthResponse>> healthCheck() async {
    final response = await get<HealthResponse>(
      '/health',
      fromJson: (json) => HealthResponse.fromJson(json),
    );

    if (response.success && response.data != null) {
      isHealthy.value = response.data!.status == 'healthy';
    } else if (response.error != null) {
      error.value = response.error!.message;
      isHealthy.value = false;
    }

    return response;
  }

  /// 就绪检查
  Future<ServiceResponse<ReadyResponse>> readinessCheck() async {
    final response = await get<ReadyResponse>(
      '/ready',
      fromJson: (json) => ReadyResponse.fromJson(json),
    );

    if (response.success && response.data != null) {
      isReady.value = response.data!.status == 'ready';
    } else if (response.error != null) {
      error.value = response.error!.message;
      isReady.value = false;
    }

    return response;
  }

  /// 存活检查
  Future<ServiceResponse<LiveResponse>> livenessCheck() async {
    final response = await get<LiveResponse>(
      '/live',
      fromJson: (json) => LiveResponse.fromJson(json),
    );

    if (response.success && response.data != null) {
      isLive.value = response.data!.status == 'alive';
    } else if (response.error != null) {
      error.value = response.error!.message;
      isLive.value = false;
    }

    return response;
  }

  /// 获取API信息
  Future<ServiceResponse<ApiInfoResponse>> getApiInfo() async {
    final response = await get<ApiInfoResponse>(
      '/',
      fromJson: (json) => ApiInfoResponse.fromJson(json),
    );

    if (response.success && response.data != null) {
      apiInfo.value = response.data!;
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 检查所有系统状态
  Future<Map<String, bool>> checkAllSystems() async {
    final results = <String, bool>{};

    // 并行执行所有检查
    final healthResult = await healthCheck();
    results['health'] = healthResult.success && isHealthy.value;

    final readyResult = await readinessCheck();
    results['ready'] = readyResult.success && isReady.value;

    final liveResult = await livenessCheck();
    results['live'] = liveResult.success && isLive.value;

    final apiResult = await getApiInfo();
    results['api'] = apiResult.success && apiInfo.value != null;

    return results;
  }

  /// 系统是否完全正常
  bool get isSystemFullyOperational {
    return isHealthy.value &&
        isReady.value &&
        isLive.value &&
        apiInfo.value != null;
  }

  /// 获取系统状态摘要
  Map<String, dynamic> get systemStatus {
    return {
      'healthy': isHealthy.value,
      'ready': isReady.value,
      'live': isLive.value,
      'apiInfo': apiInfo.value?.toJson(),
      'error': error.value,
      'fullyOperational': isSystemFullyOperational,
    };
  }

  /// 重置系统状态
  void reset() {
    isHealthy.value = false;
    isReady.value = false;
    isLive.value = false;
    apiInfo.value = null;
    error.value = '';
  }

  /// 初始化系统检查
  Future<void> initialize() async {
    // 执行基本的系统检查
    await checkAllSystems();
  }
}
