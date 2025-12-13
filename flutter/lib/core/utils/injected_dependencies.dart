import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Core
import '../api/api_client.dart';
import 'logger.dart';

final getIt = GetIt.instance;

/// 初始化依赖注入
Future<void> initDependencies() async {
  Logger.info('初始化依赖注入...');
  try {
    await _initExternalDependencies();
    await _initCoreDependencies();
    Logger.info('依赖注入初始化完成');
  } catch (e, stackTrace) {
    Logger.error('依赖注入初始化失败', e, stackTrace);
    rethrow;
  }
}

Future<void> _initExternalDependencies() async {
  Logger.debug('初始化外部依赖...');
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
}

Future<void> _initCoreDependencies() async {
  Logger.debug('初始化核心依赖...');
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
}

void resetDependencies() {
  Logger.info('重置依赖注入...');
  getIt.reset();
}

T get<T extends Object>() {
  return getIt<T>();
}
