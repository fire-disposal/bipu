/// 认证结果
library;

import '../../data/models/jwt_token.dart';

/// 认证结果
class AuthResult {
  final bool success;
  final String? message;
  final JwtToken? token;
  final Map<String, dynamic>? userInfo;

  const AuthResult({
    required this.success,
    this.message,
    this.token,
    this.userInfo,
  });

  factory AuthResult.success(JwtToken token, Map<String, dynamic>? userInfo) {
    return AuthResult(success: true, token: token, userInfo: userInfo);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }

  @override
  String toString() {
    return 'AuthResult{success: $success, message: $message, '
        'token: $token, userInfo: $userInfo}';
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

  /// 是否所有认证检查都通过
  bool get isHealthy {
    return !tokenExpired && (isAuthenticated == hasValidToken);
  }

  /// 是否需要重新认证
  bool get needsReauthentication {
    return tokenExpired || (!isAuthenticated && hasValidToken);
  }

  @override
  String toString() {
    return 'AuthStatus{isAuthenticated: $isAuthenticated, '
        'hasValidToken: $hasValidToken, tokenExpiresSoon: $tokenExpiresSoon, '
        'tokenExpired: $tokenExpired, userInfo: $userInfo}';
  }
}
