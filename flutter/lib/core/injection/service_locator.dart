/// 服务定位器
/// 提供依赖注入和服务定位功能
library;

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';
import '../foundation/logger.dart' as logger;
import '../data/data.dart';
import '../domain/domain.dart';

/// 全局服务定位器实例
final GetIt serviceLocator = GetIt.instance;

/// 服务定位器配置
class ServiceLocatorConfig {
  static bool _initialized = false;

  /// 初始化服务定位器
  static Future<void> initialize({
    AppConfig? appConfig,
    SharedPreferences? sharedPreferences,
  }) async {
    if (_initialized) return;

    try {
      logger.Logger.info('初始化服务定位器...');

      // 初始化基础依赖
      await _initializeFoundation(appConfig, sharedPreferences);

      // 初始化数据层
      await _initializeDataLayer();

      // 初始化领域层
      await _initializeDomainLayer();

      _initialized = true;
      logger.Logger.info('服务定位器初始化完成');
    } catch (e, stackTrace) {
      logger.Logger.error('服务定位器初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 初始化基础依赖
  static Future<void> _initializeFoundation(
    AppConfig? appConfig,
    SharedPreferences? sharedPreferences,
  ) async {
    logger.Logger.debug('初始化基础依赖...');

    // 应用配置
    final config = appConfig ?? AppConfig.user();
    serviceLocator.registerSingleton<AppConfig>(config);

    // SharedPreferences
    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    serviceLocator.registerSingleton<SharedPreferences>(prefs);

    // 日志级别设置 - 暂时使用固定级别，避免枚举冲突
    if (config.enableLogging) {
      logger.Logger.setLogLevel(logger.LogLevel.info);
    }
  }

  /// 初始化数据层
  static Future<void> _initializeDataLayer() async {
    logger.Logger.debug('初始化数据层...');

    // API配置
    final appConfig = serviceLocator<AppConfig>();
    final apiConfig = ApiConfig(
      baseUrl: appConfig.baseUrl,
      connectTimeout: Duration(seconds: appConfig.connectionTimeout),
      receiveTimeout: Duration(seconds: appConfig.receiveTimeout),
    );

    // API客户端
    final apiClient = ApiClientImpl(config: apiConfig);
    serviceLocator.registerSingleton<ApiClient>(apiClient);

    // JWT存储
    final jwtStorage = JwtStorageImpl(
      Future.value(serviceLocator<SharedPreferences>()),
    );
    serviceLocator.registerSingleton<JwtStorage>(jwtStorage);

    // 认证拦截器
    final authInterceptor = AuthInterceptor(jwtStorage);

    // 配置Dio拦截器
    final dio = Dio(
      BaseOptions(
        baseUrl: appConfig.baseUrl,
        connectTimeout: Duration(seconds: appConfig.connectionTimeout),
        receiveTimeout: Duration(seconds: appConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(authInterceptor);

    // OpenAPI客户端
    final openapi = Openapi(dio: dio);
    serviceLocator.registerSingleton<Openapi>(openapi);
  }

  /// 初始化领域层
  static Future<void> _initializeDomainLayer() async {
    logger.Logger.debug('初始化领域层...');

    final appConfig = serviceLocator<AppConfig>();

    // 认证服务
    final authService = AuthServiceImpl(
      openapi: serviceLocator<Openapi>(),
      jwtStorage: serviceLocator<JwtStorage>(),
    );
    serviceLocator.registerSingleton<AuthService>(authService);

    // BLE服务（如果启用）
    if (appConfig.isFeatureEnabled(AppFeature.ble)) {
      final bleService = BleServiceImpl();
      serviceLocator.registerSingleton<BleService>(bleService);

      // 设备控制服务
      final deviceControlService = DeviceControlServiceImpl(bleService);
      serviceLocator.registerSingleton<DeviceControlService>(
        deviceControlService,
      );
    }
  }

  /// 重置服务定位器
  static void reset() {
    logger.Logger.info('重置服务定位器...');
    serviceLocator.reset();
    _initialized = false;
  }

  /// 获取服务实例
  static T get<T extends Object>() {
    return serviceLocator<T>();
  }

  /// 检查服务是否已注册
  static bool isRegistered<T extends Object>() {
    return serviceLocator.isRegistered<T>();
  }
}

/// 服务定位器扩展
extension ServiceLocatorExtension on GetIt {
  /// 安全获取服务（如果未注册则返回null）
  T? getSafe<T extends Object>() {
    try {
      return get<T>();
    } catch (_) {
      return null;
    }
  }
}
