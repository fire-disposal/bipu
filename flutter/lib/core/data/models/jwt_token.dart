/// JWT令牌数据模型
library;

import 'dart:convert';

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

  /// 获取令牌剩余有效期（秒）
  int? get remainingSeconds {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  @override
  String toString() {
    return 'JwtToken{accessToken: ${accessToken.substring(0, 10)}..., '
        'refreshToken: ${refreshToken?.substring(0, 10) ?? 'null'}..., '
        'expiresAt: $expiresAt, isExpired: $isExpired}';
  }
}

/// JWT工具类
class JwtUtils {
  /// 解码JWT令牌
  static Map<String, dynamic> decodeJwt(String token) {
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

  /// 验证JWT令牌格式
  static bool isValidTokenFormat(String token) {
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
  static Map<String, dynamic>? getUserInfoFromToken(String token) {
    try {
      final decoded = decodeJwt(token);
      return {
        'userId': decoded['sub'],
        'username': decoded['username'],
        'email': decoded['email'],
        'roles': decoded['roles'],
        'exp': decoded['exp'],
      };
    } catch (e) {
      return null;
    }
  }
}
