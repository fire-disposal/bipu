import 'package:flutter/foundation.dart';
import '../storage/storage_manager.dart';

/// Token 管理器 - 统一处理 Token 的获取、保存、刷新和清除
class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Token 过期回调
  static final ValueNotifier<bool> tokenExpired = ValueNotifier<bool>(false);

  /// 保存 Token
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      if (accessToken.isEmpty) {
        throw Exception('Access token cannot be empty');
      }

      await StorageManager.setSecureData(_accessTokenKey, accessToken);
      debugPrint('✅ Access token saved: ${accessToken.substring(0, 20)}...');

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await StorageManager.setSecureData(_refreshTokenKey, refreshToken);
        debugPrint(
          '✅ Refresh token saved: ${refreshToken.substring(0, 20)}...',
        );
      }

      debugPrint('✅ All tokens saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving tokens: $e');
      rethrow;
    }
  }

  /// 获取访问 Token
  static Future<String?> getAccessToken() async {
    try {
      final token = await StorageManager.getSecureData(_accessTokenKey);
      return token?.isNotEmpty == true ? token : null;
    } catch (e) {
      debugPrint('❌ Error reading access token: $e');
      return null;
    }
  }

  /// 获取刷新 Token
  static Future<String?> getRefreshToken() async {
    try {
      return await StorageManager.getSecureData(_refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading refresh token: $e');
      return null;
    }
  }

  /// 清除所有 Token
  static Future<void> clearTokens() async {
    try {
      await StorageManager.setSecureData(_accessTokenKey, '');
      await StorageManager.setSecureData(_refreshTokenKey, '');
      tokenExpired.value = true;
      debugPrint('✅ All tokens cleared successfully from storage');
    } catch (e) {
      debugPrint('❌ Error clearing tokens from storage: $e');
      rethrow;
    }
  }

  /// 检查 Token 是否存在
  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 处理 Token 过期
  static Future<void> handleTokenExpired() async {
    debugPrint('🔒 Token expired, clearing local auth info');
    await clearTokens();
    tokenExpired.value = true;
  }
}
