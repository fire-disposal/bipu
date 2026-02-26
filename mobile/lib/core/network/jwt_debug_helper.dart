import 'package:flutter/foundation.dart';
import '../storage/storage_manager.dart';
import 'token_manager.dart';

/// JWT 调试助手 - 用于诊断 JWT 存储和附加问题
class JwtDebugHelper {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// 打印完整的 JWT 诊断信息
  static Future<void> printJwtDiagnostics() async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 JWT 诊断信息');
    debugPrint('═══════════════════════════════════════════════════════════');

    try {
      // 检查 Access Token
      final accessToken = await StorageManager.getSecureData(_tokenKey);
      debugPrint('📌 Access Token 状态:');
      if (accessToken == null) {
        debugPrint('   ❌ Access Token 为 null');
      } else if (accessToken.isEmpty) {
        debugPrint('   ❌ Access Token 为空字符串');
      } else {
        debugPrint('   ✅ Access Token 存在');
        debugPrint('   📊 长度: ${accessToken.length}');
        debugPrint('   🔤 前缀: ${accessToken.substring(0, 20)}...');
        debugPrint(
          '   🔤 后缀: ...${accessToken.substring(accessToken.length - 20)}',
        );
        _printTokenParts(accessToken);
      }

      // 检查 Refresh Token
      final refreshToken = await StorageManager.getSecureData(_refreshTokenKey);
      debugPrint('');
      debugPrint('📌 Refresh Token 状态:');
      if (refreshToken == null) {
        debugPrint('   ❌ Refresh Token 为 null');
      } else if (refreshToken.isEmpty) {
        debugPrint('   ❌ Refresh Token 为空字符串');
      } else {
        debugPrint('   ✅ Refresh Token 存在');
        debugPrint('   📊 长度: ${refreshToken.length}');
        debugPrint('   🔤 前缀: ${refreshToken.substring(0, 20)}...');
      }

      // 检查 TokenManager 的状态
      debugPrint('');
      debugPrint('📌 TokenManager 状态:');
      final hasToken = await TokenManager.hasToken();
      debugPrint('   hasToken(): $hasToken');
      debugPrint('   tokenExpired.value: ${TokenManager.tokenExpired.value}');

      // 检查 StorageManager 的统计信息
      debugPrint('');
      debugPrint('📌 StorageManager 统计:');
      final stats = await StorageManager.getStorageStats();
      debugPrint('   缓存项: ${stats.cacheItems}');
      debugPrint('   用户数据项: ${stats.userDataItems}');
      debugPrint('   设置项: ${stats.settingsItems}');
      debugPrint('   临时项: ${stats.tempItems}');
      debugPrint('   总项数: ${stats.totalItems}');
    } catch (e) {
      debugPrint('❌ 诊断过程出错: $e');
    }

    debugPrint('═══════════════════════════════════════════════════════════');
  }

  /// 打印 JWT Token 的各个部分
  static void _printTokenParts(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('   ⚠️ Token 格式不正确 (应该有 3 部分，实际: ${parts.length})');
        return;
      }

      debugPrint('   📋 Token 结构:');
      debugPrint('      Header: ${parts[0].substring(0, 20)}...');
      debugPrint('      Payload: ${parts[1].substring(0, 20)}...');
      debugPrint('      Signature: ${parts[2].substring(0, 20)}...');
    } catch (e) {
      debugPrint('   ⚠️ 无法解析 Token 结构: $e');
    }
  }

  /// 验证 Token 是否有效
  static Future<bool> validateTokenStorage() async {
    debugPrint('🔐 验证 Token 存储...');

    try {
      final token = await StorageManager.getSecureData(_tokenKey);

      if (token == null) {
        debugPrint('❌ Token 为 null - 存储失败');
        return false;
      }

      if (token.isEmpty) {
        debugPrint('❌ Token 为空 - 存储失败');
        return false;
      }

      if (!token.contains('.')) {
        debugPrint('❌ Token 格式无效 - 不是 JWT 格式');
        return false;
      }

      debugPrint('✅ Token 存储有效');
      return true;
    } catch (e) {
      debugPrint('❌ 验证过程出错: $e');
      return false;
    }
  }

  /// 清除所有 Token 并验证
  static Future<void> clearAndVerify() async {
    debugPrint('🗑️ 清除所有 Token...');

    try {
      await TokenManager.clearTokens();
      debugPrint('✅ Token 已清除');

      // 验证清除
      final token = await StorageManager.getSecureData(_tokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('✅ 验证成功: Token 已完全清除');
      } else {
        debugPrint('❌ 验证失败: Token 仍然存在');
      }
    } catch (e) {
      debugPrint('❌ 清除过程出错: $e');
    }
  }

  /// 测试 Token 保存和读取
  static Future<void> testTokenSaveAndRead(String testToken) async {
    debugPrint('🧪 测试 Token 保存和读取...');

    try {
      // 保存
      debugPrint('📝 保存测试 Token...');
      await StorageManager.setSecureData(_tokenKey, testToken);
      debugPrint('✅ Token 已保存');

      // 读取
      debugPrint('📖 读取测试 Token...');
      final readToken = await StorageManager.getSecureData(_tokenKey);

      if (readToken == testToken) {
        debugPrint('✅ Token 读写一致');
      } else {
        debugPrint('❌ Token 读写不一致');
        debugPrint('   原始: ${testToken.substring(0, 20)}...');
        debugPrint('   读取: ${readToken?.substring(0, 20) ?? 'null'}...');
      }

      // 清除
      debugPrint('🗑️ 清除测试 Token...');
      await StorageManager.setSecureData(_tokenKey, '');
      final clearedToken = await StorageManager.getSecureData(_tokenKey);

      if (clearedToken == null || clearedToken.isEmpty) {
        debugPrint('✅ Token 已清除');
      } else {
        debugPrint('❌ Token 清除失败');
      }
    } catch (e) {
      debugPrint('❌ 测试过程出错: $e');
    }
  }
}
