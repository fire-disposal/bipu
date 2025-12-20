import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Core
import '../api/api_client.dart';
import '../ble/bluetooth_service.dart';
import '../ble/device_control_service.dart';
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

  // API客户端
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // 蓝牙服务
  getIt.registerLazySingleton<BluetoothService>(() => BluetoothService());

  // 应用配置
  getIt.registerLazySingleton<AppConfig>(() => AppConfig());

  // 设备控制服务
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
