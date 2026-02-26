import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/network.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// 认证服务 - 管理用户认证状态和业务流程
class AuthService {
  static final AuthService _instance = AuthService._internal();

  final _authStateController = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  dynamic _currentUser;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  ValueNotifier<AuthStatus> get authState => _authStateController;
  dynamic get currentUser => _currentUser;

  /// 初始化认证状态
  /// 应用启动时调用，检查本地 Token 并验证有效性
  Future<void> initialize() async {
    try {
      final hasToken = await TokenManager.hasToken();
      if (hasToken) {
        try {
          await _fetchCurrentUser();
          _authStateController.value = AuthStatus.authenticated;
        } catch (e) {
          // Token 无效，清除本地数据
          await TokenManager.clearTokens();
          _authStateController.value = AuthStatus.unauthenticated;
        }
      } else {
        _authStateController.value = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _authStateController.value = AuthStatus.unauthenticated;
    }

    // 监听 Token 过期事件
    TokenManager.tokenExpired.addListener(_onTokenExpired);
  }

  /// 获取当前用户信息
  Future<void> fetchCurrentUser() async {
    await _fetchCurrentUser();
  }

  /// 用户注册
  Future<void> register({
    required String username,
    required String password,
    String? nickname,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.authentication.postApiPublicRegister(
          body: UserCreate(
            username: username,
            password: password,
            nickname: nickname,
          ),
        ),
        operationName: 'Register',
      );

      // 注册成功后自动登录
      await login(username, password);
    } on AuthException catch (e) {
      rethrow;
    } on ValidationException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// 用户登录
  Future<void> login(String username, String password) async {
    try {
      final apiClient = ApiClient.instance;
      final token = await apiClient.execute(
        () => apiClient.api.authentication.postApiPublicLogin(
          body: UserLogin(username: username, password: password),
        ),
        operationName: 'Login',
      );

      // 保存 Token
      await TokenManager.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      // 获取当前用户信息
      await _fetchCurrentUser();
      _authStateController.value = AuthStatus.authenticated;
    } on AuthException catch (e) {
      await TokenManager.clearTokens();
      rethrow;
    } on ValidationException catch (e) {
      await TokenManager.clearTokens();
      rethrow;
    } on ServerException catch (e) {
      await TokenManager.clearTokens();
      rethrow;
    } catch (e) {
      await TokenManager.clearTokens();
      rethrow;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.authentication.postApiPublicLogout(),
        operationName: 'Logout',
      );
    } catch (e) {
      // 忽略登出错误，继续清除本地数据
    } finally {
      // 无论 API 调用是否成功，都清除本地数据
      await TokenManager.clearTokens();
      _currentUser = null;
      _authStateController.value = AuthStatus.unauthenticated;
    }
  }

  /// 刷新访问 Token
  Future<void> refreshAccessToken() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw AuthException(message: 'No refresh token available');
      }

      final apiClient = ApiClient.instance;
      final token = await apiClient.execute(
        () => apiClient.api.authentication.postApiPublicRefresh(
          body: TokenRefresh(refreshToken: refreshToken),
        ),
        operationName: 'RefreshToken',
      );

      // 保存新的 Token
      await TokenManager.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
    } on AuthException catch (e) {
      // Token 刷新失败，登出用户
      await logout();
      rethrow;
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  /// 验证 Token 有效性
  Future<bool> verifyToken() async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.authentication.getApiPublicVerifyToken(),
        operationName: 'VerifyToken',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 更新用户密码
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.userProfile.putApiProfilePassword(
          body: UserPasswordUpdate(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ),
        ),
        operationName: 'UpdatePassword',
      );
    } on AuthException catch (e) {
      rethrow;
    } on ValidationException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新时区
  Future<void> updateTimezone(String timezone) async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.userProfile.putApiProfileTimezone(
          body: TimezoneUpdate(timezone: timezone),
        ),
        operationName: 'UpdateTimezone',
      );
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取当前用户信息（内部方法）
  Future<void> _fetchCurrentUser() async {
    try {
      final apiClient = ApiClient.instance;
      _currentUser = await apiClient.execute(
        () => apiClient.api.userProfile.getApiProfileMe(),
        operationName: 'GetCurrentUser',
      );
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Token 过期处理
  void _onTokenExpired() {
    if (TokenManager.tokenExpired.value) {
      _currentUser = null;
      _authStateController.value = AuthStatus.unauthenticated;
    }
  }

  /// 清理资源
  void dispose() {
    TokenManager.tokenExpired.removeListener(_onTokenExpired);
    _authStateController.dispose();
  }
}
