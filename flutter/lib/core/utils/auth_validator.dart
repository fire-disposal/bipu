/// 认证验证器
/// 验证JWT认证流程的正确性
library;

import '../core.dart';

/// 认证验证器
class AuthValidator {
  /// 验证认证流程
  static Future<bool> validateAuthFlow() async {
    try {
      Logger.info('开始验证JWT认证流程...');

      // 获取服务
      final authService = getIt<AuthService>();
      final jwtManager = getIt<JwtManager>();

      // 1. 验证初始状态
      Logger.debug('1. 验证初始状态');
      if (authService.isAuthenticated()) {
        Logger.warning('初始状态已认证，可能是之前的会话');
      }

      // 2. 验证JWT管理器
      Logger.debug('2. 验证JWT管理器');
      final initialToken = jwtManager.getCurrentToken();
      if (initialToken != null) {
        Logger.info('发现已存在的JWT令牌');
        if (initialToken.isExpired) {
          Logger.warning('JWT令牌已过期');
        } else {
          Logger.info('JWT令牌有效');
        }
      } else {
        Logger.info('当前无JWT令牌');
      }

      // 3. 验证用户信息获取
      Logger.debug('3. 验证用户信息获取');
      final userInfo = authService.getUserInfoFromToken();
      if (userInfo != null) {
        Logger.info('从令牌获取用户信息成功: ${userInfo['username']}');
      } else {
        Logger.info('无法从令牌获取用户信息');
      }

      // 4. 验证当前用户API调用
      Logger.debug('4. 验证当前用户API调用');
      final currentUser = await authService.getCurrentUser();
      if (currentUser != null) {
        Logger.info('获取当前用户成功: ${currentUser.username}');
      } else {
        Logger.info('无法获取当前用户（可能需要登录）');
      }

      Logger.info('JWT认证流程验证完成');
      return true;
    } catch (e) {
      Logger.error('JWT认证流程验证失败', e);
      return false;
    }
  }

  /// 检查认证状态
  static AuthStatus checkAuthStatus() {
    try {
      final authService = getIt<AuthService>();
      final jwtManager = getIt<JwtManager>();

      final isAuthenticated = authService.isAuthenticated();
      final hasValidToken = jwtManager.hasValidToken();
      final token = jwtManager.getCurrentToken();

      return AuthStatus(
        isAuthenticated: isAuthenticated,
        hasValidToken: hasValidToken,
        tokenExpiresSoon: token?.isAboutToExpire ?? false,
        tokenExpired: token?.isExpired ?? false,
        userInfo: authService.getUserInfoFromToken(),
      );
    } catch (e) {
      Logger.error('检查认证状态失败', e);
      return AuthStatus(
        isAuthenticated: false,
        hasValidToken: false,
        tokenExpiresSoon: false,
        tokenExpired: true,
        userInfo: null,
      );
    }
  }
}

/// 认证状态
class AuthStatus {
  final bool isAuthenticated;
  final bool hasValidToken;
  final bool tokenExpiresSoon;
  final bool tokenExpired;
  final Map<String, dynamic>? userInfo;

  const AuthStatus({
    required this.isAuthenticated,
    required this.hasValidToken,
    required this.tokenExpiresSoon,
    required this.tokenExpired,
    this.userInfo,
  });

  @override
  String toString() {
    return 'AuthStatus{'
        'isAuthenticated: $isAuthenticated, '
        'hasValidToken: $hasValidToken, '
        'tokenExpiresSoon: $tokenExpiresSoon, '
        'tokenExpired: $tokenExpired, '
        'userInfo: $userInfo'
        '}';
  }
}
