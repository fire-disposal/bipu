import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_user/core/storage/token_storage.dart';
import 'package:flutter_user/core/storage/storage_manager.dart';

class MobileTokenStorage implements TokenStorage {
  static const _boxName = 'token_box';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<Box<String>> _getBox() async {
    return await Hive.openBox<String>(_boxName);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      final box = await _getBox();
      await box.put(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        // Store refresh token in secure storage
        await StorageManager.setSecureData('refresh_token', refreshToken);
        await box.put(
          _refreshTokenKey,
          '',
        ); // keep key for compatibility (empty)
      }
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final box = await _getBox();
      return box.get(_accessTokenKey);
    } catch (e) {
      debugPrint('Error reading access token: $e');
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      // Read refresh token from secure storage
      final token = await StorageManager.getSecureData('refresh_token');
      return token;
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      final box = await _getBox();
      await box.delete(_accessTokenKey);
      await box.delete(_refreshTokenKey);
      // no guest_mode key exists
      // clear refresh token from secure storage
      try {
        await StorageManager.setSecureData('refresh_token', '');
      } catch (_) {}
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }
}
