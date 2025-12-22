/// JWT管理工具类
/// 负责JWT令牌的存储、获取、验证和刷新
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// JWT令牌信息
class JwtToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const JwtToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  /// 从JSON创建JwtToken
  factory JwtToken.fromJson(Map<String, dynamic> json) {
    return JwtToken(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// 检查令牌是否过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 检查令牌是否即将过期（5分钟内）
  bool get isAboutToExpire {
    if (expiresAt == null) return false;
    return DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt!);
  }
}

/// JWT管理器
class JwtManager {
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _expiresAtKey = 'jwt_expires_at';

  final SharedPreferences _prefs;

  JwtManager(this._prefs);

  /// 保存JWT令牌
  Future<void> saveToken(JwtToken token) async {
    try {
      await _prefs.setString(_accessTokenKey, token.accessToken);
      if (token.refreshToken != null) {
        await _prefs.setString(_refreshTokenKey, token.refreshToken!);
      }
      if (token.expiresAt != null) {
        await _prefs.setString(
          _expiresAtKey,
          token.expiresAt!.toIso8601String(),
        );
      }
      Logger.info('JWT令牌已保存');
    } catch (e) {
      Logger.error('保存JWT令牌失败', e);
      rethrow;
    }
  }

  /// 获取当前JWT令牌
  JwtToken? getCurrentToken() {
    try {
      final accessToken = _prefs.getString(_accessTokenKey);
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      final refreshToken = _prefs.getString(_refreshTokenKey);
      final expiresAtStr = _prefs.getString(_expiresAtKey);
      DateTime? expiresAt;

      if (expiresAtStr != null) {
        try {
          expiresAt = DateTime.parse(expiresAtStr);
        } catch (e) {
          Logger.warning('解析过期时间失败，使用JWT解码');
          // 如果解析失败，尝试从JWT令牌中解码过期时间
          try {
            final decoded = _decodeJwt(accessToken);
            if (decoded['exp'] != null) {
              expiresAt = DateTime.fromMillisecondsSinceEpoch(
                decoded['exp'] * 1000,
              );
            }
          } catch (decodeError) {
            Logger.error('JWT解码失败', decodeError);
          }
        }
      }

      return JwtToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
    } catch (e) {
      Logger.error('获取JWT令牌失败', e);
      return null;
    }
  }

  /// 获取当前访问令牌
  String? getAccessToken() {
    return getCurrentToken()?.accessToken;
  }

  /// 获取当前刷新令牌
  String? getRefreshToken() {
    return getCurrentToken()?.refreshToken;
  }

  /// 检查是否有有效的令牌
  bool hasValidToken() {
    final token = getCurrentToken();
    return token != null && !token.isExpired;
  }

  /// 检查令牌是否需要刷新
  bool needsTokenRefresh() {
    final token = getCurrentToken();
    return token != null && token.isAboutToExpire;
  }

  /// 清除JWT令牌
  Future<void> clearToken() async {
    try {
      await _prefs.remove(_accessTokenKey);
      await _prefs.remove(_refreshTokenKey);
      await _prefs.remove(_expiresAtKey);
      Logger.info('JWT令牌已清除');
    } catch (e) {
      Logger.error('清除JWT令牌失败', e);
      rethrow;
    }
  }

  /// 验证JWT令牌格式
  bool isValidTokenFormat(String token) {
    try {
      // JWT令牌应该由三部分组成，用点分隔
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // 尝试解码头部和载荷
      final header = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[0])),
      );
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      // 检查是否为有效的JSON
      jsonDecode(header);
      jsonDecode(payload);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 从JWT令牌获取用户信息
  Map<String, dynamic>? getUserInfoFromToken() {
    try {
      final token = getAccessToken();
      if (token == null) return null;

      final decoded = _decodeJwt(token);
      return {
        'userId': decoded['sub'],
        'username': decoded['username'],
        'email': decoded['email'],
        'roles': decoded['roles'],
        'exp': decoded['exp'],
      };
    } catch (e) {
      Logger.error('从JWT令牌获取用户信息失败', e);
      return null;
    }
  }

  /// 获取令牌剩余有效期（秒）
  int? getTokenRemainingSeconds() {
    try {
      final token = getCurrentToken();
      if (token?.expiresAt == null) return null;

      final remaining = token!.expiresAt!.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      Logger.error('获取令牌剩余有效期失败', e);
      return null;
    }
  }

  /// 解码JWT令牌
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid JWT token');
      }

      // 解码载荷部分
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Failed to decode JWT: $e');
    }
  }
}
