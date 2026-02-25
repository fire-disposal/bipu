import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/api/dio_client.dart';

/// 认证状态枚举
enum AuthStatus {
  /// 初始状态，正在检查认证状态
  unknown,

  /// 未认证（未登录）
  unauthenticated,

  /// 正在登录中
  loggingIn,

  /// 已认证（已登录）
  authenticated,

  /// 正在登出中
  loggingOut,
}

/// 认证状态数据类
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loggingIn || status == AuthStatus.loggingOut;
  bool get hasError => error != null;

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.username}, error: $error)';
}

/// 统一认证状态管理器
final authStateNotifierProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(() => AuthStateNotifier());

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 初始化时检查认证状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });

    // 注册全局实例
    AuthManager.setInstance(this);

    return const AuthState(status: AuthStatus.unknown);
  }

  /// 检查认证状态
  Future<void> _checkAuthStatus() async {
    try {
      debugPrint('[Auth] 开始检查认证状态...');
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final tokenExpiry = prefs.getInt('token_expiry');

      debugPrint(
        '[Auth] Token存在: ${accessToken != null && accessToken.isNotEmpty}',
      );
      debugPrint('[Auth] Token过期时间: $tokenExpiry');

      if (accessToken != null && accessToken.isNotEmpty) {
        // 检查token是否过期
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        debugPrint('[Auth] 当前时间戳: $now');

        if (tokenExpiry != null && tokenExpiry > now) {
          // Token有效，尝试获取用户信息
          debugPrint('[Auth] Token有效，尝试获取用户信息...');
          await loadUserProfile();
        } else {
          // Token过期，尝试刷新
          debugPrint('[Auth] Token已过期，尝试刷新...');
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final refreshSuccess = await _refreshToken(refreshToken);
            if (refreshSuccess) {
              await loadUserProfile();
            } else {
              // 刷新失败，设置为未认证
              state = const AuthState(status: AuthStatus.unauthenticated);
              debugPrint('[Auth] Token刷新失败，设置为未认证状态');
            }
          } else {
            // 没有refresh token，设置为未认证
            state = const AuthState(status: AuthStatus.unauthenticated);
            debugPrint('[Auth] 没有refresh token，设置为未认证状态');
          }
        }
      } else {
        // 没有token，设置为未认证
        state = const AuthState(status: AuthStatus.unauthenticated);
        debugPrint('[Auth] 没有token，设置为未认证状态');
      }
    } catch (e) {
      debugPrint('[Auth] 检查认证状态失败: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 加载用户资料
  Future<void> loadUserProfile() async {
    try {
      debugPrint('[Auth] 开始加载用户资料...');
      final restClient = ref.read(restClientProvider);
      final response = await restClient.getCurrentUser();

      if (response.response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        debugPrint('[Auth] 用户资料加载成功: ${user.username} (${user.bipupuId})');

        // 更新状态为已认证，并设置用户信息
        state = AuthState(status: AuthStatus.authenticated, user: user);
        debugPrint('[Auth] 认证状态更新为已认证');
      } else if (response.response.statusCode == 401) {
        // Token无效，尝试刷新
        debugPrint('[Auth] Token无效(401)，尝试刷新...');
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refresh_token');
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshSuccess = await _refreshToken(refreshToken);
          if (refreshSuccess) {
            // 刷新成功，重新加载用户资料
            await loadUserProfile();
          } else {
            // 刷新失败，设置为未认证
            state = const AuthState(status: AuthStatus.unauthenticated);
            debugPrint('[Auth] Token刷新失败，设置为未认证状态');
          }
        } else {
          // 没有refresh token，设置为未认证
          state = const AuthState(status: AuthStatus.unauthenticated);
          debugPrint('[Auth] 没有refresh token，设置为未认证状态');
        }
      } else {
        debugPrint('[Auth] 获取用户资料失败: HTTP ${response.response.statusCode}');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('[Auth] 加载用户资料失败: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 用户登录
  Future<bool> login(String username, String password) async {
    try {
      debugPrint('[Auth] 开始登录，用户名: $username');
      state = state.copyWith(status: AuthStatus.loggingIn, error: null);

      final restClient = ref.read(restClientProvider);
      final response = await restClient.login({
        'username': username,
        'password': password,
      });

      debugPrint('[Auth] 登录API响应状态码: ${response.response.statusCode}');

      // 解析Token
      final data = response.data as Map<String, dynamic>;

      if (data['access_token'] == null) {
        throw Exception('登录响应缺少 access_token');
      }

      if (data['access_token'] is! String) {
        throw Exception(
          'access_token 字段类型错误: ${data['access_token'].runtimeType}',
        );
      }

      if (data['expires_in'] == null) {
        throw Exception('登录响应缺少 expires_in');
      }

      if (data['expires_in'] is! num) {
        throw Exception('expires_in 字段类型错误: ${data['expires_in'].runtimeType}');
      }

      // 保存Token
      await _saveToken(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        expiresIn: (data['expires_in'] as num).toInt(),
      );

      // 加载用户资料
      await loadUserProfile();

      debugPrint('[Auth] 登录成功');
      return true;
    } catch (e) {
      debugPrint('[Auth] 登录失败: $e');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseLoginError(e),
      );
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(
    String username,
    String password, {
    String? nickname,
  }) async {
    try {
      debugPrint('[Auth] 开始注册，用户名: $username');
      state = state.copyWith(status: AuthStatus.loggingIn, error: null);

      final restClient = ref.read(restClientProvider);
      await restClient.register({
        'username': username,
        'password': password,
        if (nickname != null) 'nickname': nickname,
      });

      debugPrint('[Auth] 注册成功');

      // 注册成功后不自动登录，保持未认证状态
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      debugPrint('[Auth] 注册失败: $e');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseRegisterError(e),
      );
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      debugPrint('[Auth] 开始登出');
      state = state.copyWith(status: AuthStatus.loggingOut);

      // 调用登出API
      final restClient = ref.read(restClientProvider);
      try {
        await restClient.logout();
      } catch (_) {
        // 忽略登出API错误
      }

      // 清除本地存储
      await _clearToken();

      // 更新状态为未认证
      state = const AuthState(status: AuthStatus.unauthenticated);
      debugPrint('[Auth] 登出成功');
    } catch (e) {
      debugPrint('[Auth] 登出失败: $e');
      // 即使出错也清除本地token
      await _clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 刷新Token
  Future<bool> refreshToken() async {
    try {
      debugPrint('[Auth] 开始刷新Token');
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[Auth] 没有refresh token');
        return false;
      }

      return await _refreshToken(refreshToken);
    } catch (e) {
      debugPrint('[Auth] 刷新Token失败: $e');
      return false;
    }
  }

  /// 内部刷新Token方法
  Future<bool> _refreshToken(String refreshToken) async {
    try {
      debugPrint('[Auth] 调用刷新TokenAPI');
      final restClient = ref.read(restClientProvider);
      final response = await restClient.refreshToken({
        'refresh_token': refreshToken,
      });

      final data = response.data as Map<String, dynamic>;

      if (data['access_token'] == null) {
        debugPrint('[Auth] 刷新Token响应缺少 access_token');
        return false;
      }

      // 保存新的Token
      await _saveToken(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        expiresIn: (data['expires_in'] as num).toInt(),
      );

      debugPrint('[Auth] Token刷新成功');
      return true;
    } catch (e) {
      debugPrint('[Auth] 刷新Token失败: $e');
      return false;
    }
  }

  /// 保存Token到本地存储
  Future<void> _saveToken({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
  }) async {
    try {
      debugPrint('[Auth] 保存Token到本地存储');
      final prefs = await SharedPreferences.getInstance();

      // 计算过期时间戳
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiry = now + expiresIn;

      await prefs.setString('access_token', accessToken);
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
      }
      await prefs.setInt('token_expiry', expiry);

      debugPrint('[Auth] Token保存成功，过期时间: $expiry ($expiresIn秒后)');
    } catch (e) {
      debugPrint('[Auth] 保存Token失败: $e');
      rethrow;
    }
  }

  /// 清除本地存储的Token
  Future<void> _clearToken() async {
    try {
      debugPrint('[Auth] 清除本地Token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');
      debugPrint('[Auth] Token清除成功');
    } catch (e) {
      debugPrint('[Auth] 清除Token失败: $e');
    }
  }

  /// 内部清除Token方法（供AuthManager使用）
  Future<void> clearTokenInternal() async {
    await _clearToken();
  }

  /// 解析登录错误
  String _parseLoginError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('Invalid credentials') ||
        errorStr.contains('用户名或密码错误')) {
      return '用户名或密码错误';
    } else if (errorStr.contains('User not found')) {
      return '用户不存在';
    } else if (errorStr.contains('Connection refused') ||
        errorStr.contains('connection error')) {
      return '无法连接到服务器';
    } else if (errorStr.contains('timeout')) {
      return '连接超时，请检查网络';
    } else if (errorStr.contains('401')) {
      return '用户名或密码错误';
    } else if (errorStr.contains('429')) {
      return '登录尝试过于频繁，请稍后再试';
    } else {
      return '登录失败，请稍后重试';
    }
  }

  /// 解析注册错误
  String _parseRegisterError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('already exists') || errorStr.contains('已存在')) {
      return '用户名已存在';
    } else if (errorStr.contains('Connection refused') ||
        errorStr.contains('connection error')) {
      return '无法连接到服务器';
    } else if (errorStr.contains('timeout')) {
      return '连接超时，请检查网络';
    } else if (errorStr.contains('400')) {
      return '注册信息不符合要求';
    } else {
      return '注册失败，请稍后重试';
    }
  }

  /// 获取当前用户（如果已认证）
  UserModel? get currentUser => state.user;

  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// 手动检查认证状态（用于调试）
  Future<void> debugCheckAuth() async {
    debugPrint('[Auth] 手动检查认证状态...');
    await _checkAuthStatus();
    debugPrint('[Auth] 当前状态: ${state.status}');
  }
}

/// 便捷提供者
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateNotifierProvider).isAuthenticated;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateNotifierProvider).user;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateNotifierProvider).error;
});
