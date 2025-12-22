import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openapi/openapi.dart';
// Core
import '../api/api_service.dart';
import '../api/auth_service.dart';
import '../ble/bluetooth_service.dart';
import '../ble/device_control_service.dart';
import '../utils/jwt_manager.dart';
import 'logger.dart';
import 'app_config.dart';
// User App State
import '../../app_user/state/user_data_cubit.dart' as user_data;
import '../../app_user/state/device_control_state.dart';

final getIt = GetIt.instance;

/// 初始化依赖注入
Future<void> initDependencies() async {
  Logger.info('初始化依赖注入...');
  try {
    await _initExternalDependencies();
    await _initCoreDependencies();
    await _initAppSpecificDependencies();
    Logger.info('依赖注入初始化完成');
  } catch (e, stackTrace) {
    Logger.error('依赖注入初始化失败', e, stackTrace);
    rethrow;
  }
}

Future<void> _initExternalDependencies() async {
  Logger.debug('初始化外部依赖...');

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Dio HTTP客户端
  final dio = Dio();
  final appConfig = AppConfig();
  // 立即注册AppConfig，以便后续使用
  getIt.registerLazySingleton<AppConfig>(() => appConfig);

  dio.options = BaseOptions(
    baseUrl: appConfig.baseUrl,
    connectTimeout: Duration(seconds: appConfig.connectionTimeout),
    receiveTimeout: Duration(seconds: appConfig.receiveTimeout),
    headers: {'Content-Type': 'application/json'},
  );
  getIt.registerLazySingleton<Dio>(() => dio);

  // 网络连接状态
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
}

Future<void> _initCoreDependencies() async {
  Logger.debug('初始化核心依赖...');

  // JWT管理器
  final jwtManager = JwtManager(getIt<SharedPreferences>());
  getIt.registerLazySingleton<JwtManager>(() => jwtManager);

  // OpenAPI客户端 - 使用AppConfig中的配置
  final appConfig = getIt<AppConfig>();
  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.baseUrl,
      connectTimeout: Duration(seconds: appConfig.connectionTimeout),
      receiveTimeout: Duration(seconds: appConfig.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // 添加JWT认证拦截器
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // 添加JWT令牌到请求头
        final token = jwtManager.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 处理401错误，尝试刷新令牌或跳转到登录
        if (error.response?.statusCode == 401) {
          Logger.warning('JWT令牌无效或过期');

          // 清除过期的令牌
          await jwtManager.clearToken();

          // 这里可以添加刷新令牌的逻辑，或者通知应用跳转到登录页面
          // 暂时直接返回错误
        }
        handler.next(error);
      },
    ),
  );

  final openApi = Openapi(dio: dio);
  getIt.registerLazySingleton<Openapi>(() => openApi);

  // API服务 - 包装OpenAPI客户端并支持JWT
  getIt.registerLazySingleton<CoreApi>(
    () => CoreApi(openapi: openApi, jwtManager: jwtManager),
  );

  // 认证服务
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(openapi: openApi, jwtManager: jwtManager),
  );

  // 蓝牙服务 - 移除单例模式，使用DI管理
  getIt.registerLazySingleton<BluetoothService>(() => BluetoothService());

  // 设备控制服务 - 移除单例模式，使用DI管理
  getIt.registerLazySingleton<DeviceControlService>(
    () => DeviceControlService(),
  );
}

Future<void> _initAppSpecificDependencies() async {
  Logger.debug('初始化应用特定依赖...');
  // 这里可以添加用户端或管理端特定的依赖
  // 例如：用户状态管理、权限管理等

  // 用户数据管理
  getIt.registerLazySingleton(() => user_data.UserDataCubit());

  // 设备控制管理
  getIt.registerLazySingleton(
    () =>
        DeviceControlCubit(deviceControlService: getIt<DeviceControlService>()),
  );
}

void resetDependencies() {
  Logger.info('重置依赖注入...');
  getIt.reset();
}

T get<T extends Object>() {
  return getIt<T>();
}
