import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    // 初始化时检查认证状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
    return AuthStatus.unknown;
  }

  /// 手动检查认证状态（用于调试）
  Future<void> debugCheckAuth() async {
    debugPrint('[Auth] 手动检查认证状态...');
    await _checkAuth();
    debugPrint('[Auth] 当前状态: $state');
  }

  /// 检查认证状态
  Future<void> _checkAuth() async {
    try {
      debugPrint('[Auth] 开始检查认证状态...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final expiry = prefs.getInt('token_expiry');

      debugPrint('[Auth] Token存在: ${token != null && token.isNotEmpty}');
      debugPrint('[Auth] Token过期时间: $expiry');

      if (token != null && token.isNotEmpty) {
        // 检查 token 是否过期
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        debugPrint('[Auth] 当前时间戳: $now');

        if (expiry != null && expiry > now) {
          // Token 有效，已登录
          state = AuthStatus.authenticated;
          debugPrint('[Auth] 已登录（token 有效）');
        } else {
          // Token 过期，尝试刷新
          debugPrint('[Auth] Token已过期或即将过期');
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null && refreshToken.isNotEmpty) {
            debugPrint('[Auth] 尝试刷新Token...');
            await _refreshTokenInternal(refreshToken);
          } else {
            state = AuthStatus.unauthenticated;
            debugPrint('[Auth] 未登录（token 过期且无refresh token）');
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
    debugPrint('[Auth] 开始登录，用户名: $username');

    try {
      final restClient = ref.read(restClientProvider);
      debugPrint('[Auth] 调用登录API...');
      final response = await restClient.login({
        'username': username,
        'password': password,
      });

      debugPrint('[Auth] 登录API响应状态码: ${response.response.statusCode}');
      debugPrint('[Auth] 响应数据: ${response.data}');

      // 解析 Token
      final data = response.data as Map<String, dynamic>;
      debugPrint('[Auth] 原始响应数据: $data');

      // 检查必要字段
      if (data['access_token'] == null) {
        throw Exception('登录响应缺少 access_token');
      }

      // 检查字段类型，避免类型转换错误
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

      final token = Token.fromJson(data);
      debugPrint('[Auth] Token解析成功: ${token.accessToken.substring(0, 20)}...');
      await _saveToken(token);

      // 验证token是否保存成功
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('access_token');
      debugPrint('[Auth] Token保存验证: ${savedToken != null ? "成功" : "失败"}');

      // 使用 Future.microtask 确保在下一个事件循环中更新状态
      Future.microtask(() {
        if (state != AuthStatus.loggingIn) {
          debugPrint('[Auth] 状态已变更，跳过更新: $state');
          return;
        }
        state = AuthStatus.authenticated;
        debugPrint('[Auth] 登录成功，状态更新为authenticated');
      });
      return true;
    } catch (e) {
      debugPrint('[Auth] 登录失败：$e');
      debugPrint('[Auth] 错误类型: ${e.runtimeType}');
      debugPrint('[Auth] 错误堆栈: ${e.toString()}');
      Future.microtask(() {
        if (state != AuthStatus.loggingIn) {
          debugPrint('[Auth] 状态已变更，跳过更新: $state');
          return;
        }
        state = AuthStatus.unauthenticated;
      });
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
      Future.microtask(() {
        if (state != AuthStatus.registering) {
          debugPrint('[Auth] 状态已变更，跳过更新: $state');
          return;
        }
        state = AuthStatus.unauthenticated;
      });
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
    Future.microtask(() {
      if (state != AuthStatus.loggingOut) {
        debugPrint('[Auth] 状态已变更，跳过更新: $state');
        return;
      }
      state = AuthStatus.unauthenticated;
      debugPrint('[Auth] 登出成功');
    });
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

      final data = response.data as Map<String, dynamic>;
      debugPrint('[Auth] 刷新Token响应数据: $data');

      // 检查必要字段
      if (data['access_token'] == null) {
        throw Exception('刷新Token响应缺少 access_token');
      }

      // 检查字段类型，避免类型转换错误
      if (data['access_token'] is! String) {
        throw Exception(
          'access_token 字段类型错误: ${data['access_token'].runtimeType}',
        );
      }

      if (data['expires_in'] == null) {
        throw Exception('刷新Token响应缺少 expires_in');
      }

      if (data['expires_in'] is! num) {
        throw Exception('expires_in 字段类型错误: ${data['expires_in'].runtimeType}');
      }

      final token = Token.fromJson(data);
      await _saveToken(token);

      Future.microtask(() {
        state = AuthStatus.authenticated;
      });
      debugPrint('[Auth] Token 刷新成功');
      return true;
    } catch (e) {
      debugPrint('[Auth] Token 刷新失败：$e');
      await _clearToken();
      Future.microtask(() {
        state = AuthStatus.unauthenticated;
      });
      return false;
    }
  }

  /// 保存 Token 到本地存储
  Future<void> _saveToken(Token token) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint(
      '[Auth] 保存access_token: ${token.accessToken.substring(0, 20)}...',
    );
    await prefs.setString('access_token', token.accessToken);

    if (token.refreshToken != null) {
      debugPrint(
        '[Auth] 保存refresh_token: ${token.refreshToken!.substring(0, 20)}...',
      );
      await prefs.setString('refresh_token', token.refreshToken!);
    } else {
      debugPrint('[Auth] 无refresh_token');
    }

    // 保存过期时间（秒转毫秒）
    final expiry = DateTime.now().add(Duration(seconds: token.expiresIn));
    final expiryTimestamp = expiry.millisecondsSinceEpoch ~/ 1000;
    debugPrint('[Auth] Token过期时间: $expiryTimestamp (${token.expiresIn}秒后)');
    await prefs.setInt('token_expiry', expiryTimestamp);

    // 验证保存
    final savedToken = prefs.getString('access_token');
    final savedExpiry = prefs.getInt('token_expiry');
    debugPrint(
      '[Auth] 保存验证 - access_token: ${savedToken != null ? "成功" : "失败"}',
    );
    debugPrint(
      '[Auth] 保存验证 - token_expiry: ${savedExpiry != null ? "成功" : "失败"}',
    );
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
