import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/user_model.dart';

/// 认证状态
enum AuthStatus {
  /// 未知（正在检查）
  unknown,

  /// 未登录
  unauthenticated,

  /// 已登录
  authenticated,

  /// 登录中
  loggingIn,

  /// 注册中
  registering,

  /// 登出中
  loggingOut,
}

/// 认证状态提供者（使用 Notifier 模式）
final authStatusNotifierProvider =
    NotifierProvider<AuthStatusNotifier, AuthStatus>(
      () => AuthStatusNotifier(),
    );

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    // 初始化时检查认证状态
    _checkAuth();
    return AuthStatus.unknown;
  }

  /// 检查认证状态
  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final expiry = prefs.getInt('token_expiry');

      if (token != null && token.isNotEmpty) {
        // 检查 token 是否过期
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiry != null && expiry > now) {
          // Token 有效，已登录
          state = AuthStatus.authenticated;
          debugPrint('[Auth] 已登录（token 有效）');
        } else {
          // Token 过期，尝试刷新
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await _refreshTokenInternal(refreshToken);
          } else {
            state = AuthStatus.unauthenticated;
            debugPrint('[Auth] 未登录（token 过期）');
          }
        }
      } else {
        state = AuthStatus.unauthenticated;
        debugPrint('[Auth] 未登录（无 token）');
      }
    } catch (e) {
      debugPrint('[Auth] 检查认证状态失败：$e');
      state = AuthStatus.unauthenticated;
    }
  }

  /// 用户登录
  Future<bool> login(String username, String password) async {
    state = AuthStatus.loggingIn;

    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.login({
        'username': username,
        'password': password,
      });

      // 解析 Token
      final token = Token.fromJson(response.data);
      await _saveToken(token);

      state = AuthStatus.authenticated;
      debugPrint('[Auth] 登录成功：${token.user?.username}');
      return true;
    } catch (e) {
      debugPrint('[Auth] 登录失败：$e');
      state = AuthStatus.unauthenticated;
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(
    String username,
    String password, {
    String? nickname,
  }) async {
    state = AuthStatus.registering;

    try {
      final restClient = ref.read(restClientProvider);
      await restClient.register({
        'username': username,
        'password': password,
        if (nickname != null) 'nickname': nickname,
      });

      debugPrint('[Auth] 注册成功');

      // 注册后不自动登录，让用户手动登录
      state = AuthStatus.unauthenticated;
      return true;
    } catch (e) {
      debugPrint('[Auth] 注册失败：$e');
      state = AuthStatus.unauthenticated;
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    state = AuthStatus.loggingOut;

    try {
      final restClient = ref.read(restClientProvider);
      // 调用登出 API（将 token 加入黑名单）
      try {
        await restClient.logout();
      } catch (_) {
        // 忽略登出API错误
      }
    } catch (e) {
      debugPrint('[Auth] 登出 API 调用失败：$e');
    }

    // 清除本地存储
    await _clearToken();
    state = AuthStatus.unauthenticated;
    debugPrint('[Auth] 登出成功');
  }

  /// 刷新 Token
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      return await _refreshTokenInternal(refreshToken);
    } catch (e) {
      debugPrint('[Auth] 刷新 Token 失败：$e');
      return false;
    }
  }

  /// 内部方法：刷新 Token
  Future<bool> _refreshTokenInternal(String refreshToken) async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.refreshToken({
        'refresh_token': refreshToken,
      });

      final token = Token.fromJson(response.data);
      await _saveToken(token);

      state = AuthStatus.authenticated;
      debugPrint('[Auth] Token 刷新成功');
      return true;
    } catch (e) {
      debugPrint('[Auth] Token 刷新失败：$e');
      await _clearToken();
      state = AuthStatus.unauthenticated;
      return false;
    }
  }

  /// 保存 Token 到本地存储
  Future<void> _saveToken(Token token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token.accessToken);
    if (token.refreshToken != null) {
      await prefs.setString('refresh_token', token.refreshToken!);
    }
    // 保存过期时间（秒转毫秒）
    final expiry = DateTime.now().add(Duration(seconds: token.expiresIn));
    await prefs.setInt('token_expiry', expiry.millisecondsSinceEpoch ~/ 1000);
  }

  /// 清除本地存储的 Token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
  }

  /// 获取当前用户信息
  Future<UserModel?> getCurrentUser() async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.getCurrentUser();
      return UserModel.fromJson(response.data);
    } catch (e) {
      debugPrint('[Auth] 获取用户信息失败：$e');
      return null;
    }
  }

  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}

/// 是否已登录提供者
final isLoggedInProvider = Provider<bool>((ref) {
  final status = ref.watch(authStatusNotifierProvider);
  return status == AuthStatus.authenticated;
});

/// 当前用户信息提供者
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final status = ref.watch(authStatusNotifierProvider);
  if (status != AuthStatus.authenticated) {
    return null;
  }
  return ref.read(authStatusNotifierProvider.notifier).getCurrentUser();
});
