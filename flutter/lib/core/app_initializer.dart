/// 应用初始化器
/// 提供统一的应用初始化功能
library;

import 'core.dart';

/// 应用初始化器
class AppInitializer {
  /// 初始化所有核心模块
  static Future<void> initialize({
    bool enableBluetooth = true,
    bool validateAuth = true,
    String? baseUrl,
  }) async {
    try {
      Logger.info('开始初始化应用...');

      // 1. 初始化服务定位器
      Logger.debug('初始化服务定位器...');
      await ServiceLocatorConfig.initialize();

      // 2. 初始化API客户端
      Logger.debug('初始化API客户端...');
      final appConfig = ServiceLocatorConfig.get<AppConfig>();
      final actualBaseUrl = baseUrl ?? appConfig.baseUrl;
      Logger.info('API基础地址: $actualBaseUrl');

      // 3. 初始化认证状态
      Logger.debug('初始化认证状态...');
      final authService = ServiceLocatorConfig.get<AuthService>();
      // 初始化认证状态 - 使用新的认证服务接口
      final authStatus = await authService.getAuthStatus();
      Logger.info('认证状态已初始化: $authStatus');

      // 4. 验证JWT认证流程（可选）
      if (validateAuth) {
        try {
          final authStatus = await authService.getAuthStatus();
          Logger.info('认证状态: $authStatus');
        } catch (e) {
          Logger.warning('JWT认证验证失败: $e');
        }
      }

      // 5. 初始化蓝牙服务（可选）
      if (enableBluetooth && appConfig.isFeatureEnabled(AppFeature.ble)) {
        try {
          Logger.debug('初始化蓝牙服务...');
          final bleService = ServiceLocatorConfig.get<BleService>();
          await bleService.initialize();
          Logger.info('蓝牙服务初始化完成');
        } catch (e) {
          Logger.warning('蓝牙服务初始化失败，将在需要时重试: $e');
          // 蓝牙初始化失败不影响应用主要功能
        }
      }

      Logger.info('应用初始化完成');
    } catch (e, stackTrace) {
      Logger.error('应用初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 重置所有核心模块
  static Future<void> reset() async {
    try {
      Logger.info('开始重置应用...');

      // 1. 清除认证信息
      final authService = ServiceLocatorConfig.get<AuthService>();
      await authService.logout();

      // 2. 重置服务定位器
      ServiceLocatorConfig.reset();

      Logger.info('应用重置完成');
    } catch (e, stackTrace) {
      Logger.error('应用重置失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取应用状态
  static Future<AppStatus> getStatus() async {
    try {
      final authService = ServiceLocatorConfig.get<AuthService>();
      final authStatus = await authService.getAuthStatus();

      return AppStatus(
        isAuthenticated: authStatus.isAuthenticated,
        hasValidToken: authStatus.hasValidToken,
        isHealthy: authStatus.isHealthy,
        needsReauthentication: authStatus.needsReauthentication,
      );
    } catch (e) {
      Logger.error('获取应用状态失败', e);
      return const AppStatus(
        isAuthenticated: false,
        hasValidToken: false,
        isHealthy: false,
        needsReauthentication: true,
      );
    }
  }
}

/// 应用状态
class AppStatus {
  final bool isAuthenticated;
  final bool hasValidToken;
  final bool isHealthy;
  final bool needsReauthentication;

  const AppStatus({
    required this.isAuthenticated,
    required this.hasValidToken,
    required this.isHealthy,
    required this.needsReauthentication,
  });

  @override
  String toString() {
    return 'AppStatus{'
        'isAuthenticated: $isAuthenticated, '
        'hasValidToken: $hasValidToken, '
        'isHealthy: $isHealthy, '
        'needsReauthentication: $needsReauthentication'
        '}';
  }
}
