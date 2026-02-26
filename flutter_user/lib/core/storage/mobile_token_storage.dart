import 'package:flutter/foundation.dart';
import 'package:flutter_user/core/storage/token_storage.dart';
import 'package:flutter_user/core/storage/storage_manager.dart';

class MobileTokenStorage implements TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await StorageManager.setSecureData(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await StorageManager.setSecureData(_refreshTokenKey, refreshToken);
      }
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await StorageManager.getSecureData(_accessTokenKey);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await StorageManager.getSecureData(_refreshTokenKey);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await StorageManager.setSecureData(_accessTokenKey, '');
      await StorageManager.setSecureData(_refreshTokenKey, '');
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }
}
