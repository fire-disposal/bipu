import 'package:flutter/foundation.dart';
import 'package:flutter_core/core/storage/token_storage.dart';
import 'package:web/web.dart' as web;

/// Web 环境下的令牌存储实现
/// 使用 localStorage 作为备选方案，因为 FlutterSecureStorage 在非安全上下文中不可用
class WebTokenStorage implements TokenStorage {
  static const _accessTokenKey = 'bipupu_admin_access_token';
  static const _refreshTokenKey = 'bipupu_admin_refresh_token';

  // 检查是否在安全上下文中
  bool get _isSecureContext {
    try {
      return web.window.isSecureContext ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      // 使用 localStorage 作为备选方案
      web.window.localStorage.setItem(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        web.window.localStorage.setItem(_refreshTokenKey, refreshToken);
      }
      debugPrint('Tokens saved to localStorage');
    } catch (e) {
      debugPrint('Error saving tokens to localStorage: $e');
      // 如果 localStorage 也失败，尝试使用 sessionStorage
      try {
        web.window.sessionStorage.setItem(_accessTokenKey, accessToken);
        if (refreshToken != null) {
          web.window.sessionStorage.setItem(_refreshTokenKey, refreshToken);
        }
        debugPrint('Tokens saved to sessionStorage');
      } catch (e2) {
        debugPrint('Error saving tokens to sessionStorage: $e2');
      }
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      // 优先从 localStorage 读取
      final token = web.window.localStorage.getItem(_accessTokenKey);
      if (token != null) {
        return token;
      }
      // 如果 localStorage 没有，尝试 sessionStorage
      return web.window.sessionStorage.getItem(_accessTokenKey);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      // 优先从 localStorage 读取
      final token = web.window.localStorage.getItem(_refreshTokenKey);
      if (token != null) {
        return token;
      }
      // 如果 localStorage 没有，尝试 sessionStorage
      return web.window.sessionStorage.getItem(_refreshTokenKey);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      web.window.localStorage.removeItem(_accessTokenKey);
      web.window.localStorage.removeItem(_refreshTokenKey);
      web.window.sessionStorage.removeItem(_accessTokenKey);
      web.window.sessionStorage.removeItem(_refreshTokenKey);
      debugPrint('Tokens cleared from storage');
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }
}
