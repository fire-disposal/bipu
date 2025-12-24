/// JWT存储接口
library;

import '../models/jwt_token.dart';

/// JWT存储接口
abstract class JwtStorage {
  /// 保存JWT令牌
  Future<void> saveToken(JwtToken token);

  /// 获取当前JWT令牌
  Future<JwtToken?> getToken();

  /// 清除JWT令牌
  Future<void> clearToken();

  /// 检查是否存在有效令牌
  Future<bool> hasValidToken();
}

/// JWT存储实现 - 基于SharedPreferences
class JwtStorageImpl implements JwtStorage {
  final Future<dynamic> _sharedPreferences;

  JwtStorageImpl(this._sharedPreferences);

  @override
  Future<void> saveToken(JwtToken token) async {
    final prefs = await _sharedPreferences;
    await prefs.setString('jwt_access_token', token.accessToken);
    if (token.refreshToken != null) {
      await prefs.setString('jwt_refresh_token', token.refreshToken!);
    }
    if (token.expiresAt != null) {
      await prefs.setString(
        'jwt_expires_at',
        token.expiresAt!.toIso8601String(),
      );
    }
  }

  @override
  Future<JwtToken?> getToken() async {
    final prefs = await _sharedPreferences;
    final accessToken = prefs.getString('jwt_access_token');
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final refreshToken = prefs.getString('jwt_refresh_token');
    final expiresAtStr = prefs.getString('jwt_expires_at');
    DateTime? expiresAt;

    if (expiresAtStr != null) {
      try {
        expiresAt = DateTime.parse(expiresAtStr);
      } catch (e) {
        // 如果解析失败，尝试从JWT令牌中解码过期时间
        try {
          final decoded = JwtUtils.decodeJwt(accessToken);
          if (decoded['exp'] != null) {
            expiresAt = DateTime.fromMillisecondsSinceEpoch(
              decoded['exp'] * 1000,
            );
          }
        } catch (decodeError) {
          // JWT解码失败，忽略过期时间
        }
      }
    }

    return JwtToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> clearToken() async {
    final prefs = await _sharedPreferences;
    await prefs.remove('jwt_access_token');
    await prefs.remove('jwt_refresh_token');
    await prefs.remove('jwt_expires_at');
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && !token.isExpired;
  }
}
