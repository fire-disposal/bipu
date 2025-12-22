/// 核心模块初始化器
/// 提供统一的核心模块初始化功能
library;

import 'package:openapi/openapi.dart';
import 'core.dart';

/// 核心初始化器
class CoreInitializer {
  /// 初始化所有核心模块
  static Future<void> initialize({
    bool enableBluetooth = true,
    bool validateAuth = true,
    String? baseUrl,
  }) async {
    try {
      Logger.info('开始初始化核心模块...');

      // 1. 初始化依赖注入
      Logger.debug('初始化依赖注入...');
      await initDependencies();

      // 2. 初始化API客户端
      Logger.debug('初始化API客户端...');
      final openapi = getIt<Openapi>();
      CoreApi.init(
        dio: openapi.dio,
        baseUrl: baseUrl ?? openapi.dio.options.baseUrl,
      );

      // 3. 初始化认证状态
      Logger.debug('初始化认证状态...');
      final authService = getIt<AuthService>();
      await authService.initializeAuth();

      // 4. 验证JWT认证流程（可选）
      if (validateAuth) {
        try {
          await AuthValidator.validateAuthFlow();
          final authStatus = AuthValidator.checkAuthStatus();
          Logger.info('认证状态: $authStatus');
        } catch (e) {
          Logger.warning('JWT认证验证失败: $e');
        }
      }

      // 5. 初始化蓝牙服务（可选）
      if (enableBluetooth) {
        try {
          Logger.debug('初始化蓝牙服务...');
          final bluetoothService = getIt<BluetoothService>();
          await bluetoothService.initialize();
          Logger.info('蓝牙服务初始化完成');
        } catch (e) {
          Logger.warning('蓝牙服务初始化失败，将在需要时重试: $e');
          // 蓝牙初始化失败不影响应用主要功能
        }
      }

      Logger.info('核心模块初始化完成');
    } catch (e, stackTrace) {
      Logger.error('核心模块初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 重置所有核心模块
  static Future<void> reset() async {
    try {
      Logger.info('开始重置核心模块...');

      // 1. 清除认证信息
      final authService = getIt<AuthService>();
      await authService.logout();

      // 2. 重置依赖注入
      resetDependencies();

      Logger.info('核心模块重置完成');
    } catch (e, stackTrace) {
      Logger.error('核心模块重置失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取核心模块状态
  static CoreModuleStatus getStatus() {
    try {
      final authService = getIt<AuthService>();
      final jwtManager = getIt<JwtManager>();
      final bluetoothService = getIt<BluetoothService>();

      return CoreModuleStatus(
        isAuthenticated: authService.isAuthenticated(),
        hasValidToken: jwtManager.hasValidToken(),
        isBluetoothInitialized: bluetoothService.isInitialized,
        tokenExpiresSoon:
            jwtManager.getCurrentToken()?.isAboutToExpire ?? false,
        tokenExpired: jwtManager.getCurrentToken()?.isExpired ?? false,
      );
    } catch (e) {
      Logger.error('获取核心模块状态失败', e);
      return CoreModuleStatus(
        isAuthenticated: false,
        hasValidToken: false,
        isBluetoothInitialized: false,
        tokenExpiresSoon: false,
        tokenExpired: true,
      );
    }
  }
}

/// 核心模块状态
class CoreModuleStatus {
  final bool isAuthenticated;
  final bool hasValidToken;
  final bool isBluetoothInitialized;
  final bool tokenExpiresSoon;
  final bool tokenExpired;

  const CoreModuleStatus({
    required this.isAuthenticated,
    required this.hasValidToken,
    required this.isBluetoothInitialized,
    required this.tokenExpiresSoon,
    required this.tokenExpired,
  });

  @override
  String toString() {
    return 'CoreModuleStatus{'
        'isAuthenticated: $isAuthenticated, '
        'hasValidToken: $hasValidToken, '
        'isBluetoothInitialized: $isBluetoothInitialized, '
        'tokenExpiresSoon: $tokenExpiresSoon, '
        'tokenExpired: $tokenExpired'
        '}';
  }

  /// 是否所有核心模块都正常
  bool get isHealthy {
    return !tokenExpired && (isAuthenticated == hasValidToken);
  }

  /// 是否需要重新认证
  bool get needsReauthentication {
    return tokenExpired || (!isAuthenticated && hasValidToken);
  }
}
