import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/logic/auth_notifier.dart';
import '../config/app_config.dart';

/// Token刷新服务 - 用于在token过期前自动刷新
class TokenRefreshService {
  Timer? _refreshTimer;
  Timer? _expiryCheckTimer;
  final AuthStatusNotifier _authNotifier;

  TokenRefreshService(this._authNotifier);

  /// 启动token自动刷新服务
  void start() {
    debugPrint('[TokenRefreshService] 启动token自动刷新服务');

    // 立即检查一次token状态
    _checkAndScheduleRefresh();

    // 每5分钟检查一次token状态（避免频繁检查）
    _expiryCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkAndScheduleRefresh(),
    );
  }

  /// 停止token自动刷新服务
  void stop() {
    debugPrint('[TokenRefreshService] 停止token自动刷新服务');
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = null;
  }

  /// 检查并安排刷新
  Future<void> _checkAndScheduleRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final expiry = prefs.getInt('token_expiry');

      // 如果没有token或过期时间，不需要安排刷新
      if (token == null || token.isEmpty || expiry == null) {
        debugPrint('[TokenRefreshService] 无有效token，跳过刷新安排');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeUntilExpiry = expiry - now;

      debugPrint('[TokenRefreshService] Token剩余有效期: ${timeUntilExpiry}秒');

      // 如果token已经过期，立即刷新
      if (timeUntilExpiry <= 0) {
        debugPrint('[TokenRefreshService] Token已过期，立即刷新');
        await _refreshToken();
        return;
      }

      // 如果token将在5分钟内过期，安排刷新
      if (timeUntilExpiry <= 300) {
        // 5分钟 = 300秒
        debugPrint('[TokenRefreshService] Token将在5分钟内过期，立即刷新');
        await _refreshToken();
        return;
      }

      // 计算刷新时间：在token过期前10分钟刷新
      final refreshTime = timeUntilExpiry - 600; // 10分钟 = 600秒

      if (refreshTime > 0) {
        debugPrint('[TokenRefreshService] 安排在${refreshTime}秒后刷新token');
        _scheduleRefresh(refreshTime);
      } else {
        // 如果剩余时间不足10分钟，立即刷新
        debugPrint('[TokenRefreshService] Token剩余时间不足10分钟，立即刷新');
        await _refreshToken();
      }
    } catch (e) {
      debugPrint('[TokenRefreshService] 检查token状态失败: $e');
    }
  }

  /// 安排token刷新
  void _scheduleRefresh(int seconds) {
    // 取消现有的定时器
    _refreshTimer?.cancel();

    // 创建新的定时器
    _refreshTimer = Timer(Duration(seconds: seconds), () async {
      debugPrint('[TokenRefreshService] 执行预定的token刷新');
      await _refreshToken();

      // 刷新后重新安排下一次刷新
      _checkAndScheduleRefresh();
    });
  }

  /// 刷新token
  Future<void> _refreshToken() async {
    try {
      debugPrint('[TokenRefreshService] 开始刷新token');

      // 使用静默刷新，避免影响UI状态
      final success = await _authNotifier.silentRefreshToken();

      if (success) {
        debugPrint('[TokenRefreshService] Token刷新成功');
      } else {
        debugPrint('[TokenRefreshService] Token刷新失败');

        // 如果静默刷新失败，尝试使用常规刷新
        final regularSuccess = await _authNotifier.refreshToken();
        if (!regularSuccess) {
          debugPrint('[TokenRefreshService] 常规刷新也失败，可能需要重新登录');
        }
      }
    } catch (e) {
      debugPrint('[TokenRefreshService] 刷新token时发生异常: $e');
    }
  }

  /// 手动触发token刷新（可用于调试或特定场景）
  Future<bool> manualRefresh() async {
    debugPrint('[TokenRefreshService] 手动触发token刷新');
    return await _authNotifier.refreshToken();
  }

  /// 检查token是否即将过期（用于在关键操作前检查）
  Future<bool> isTokenAboutToExpire({int thresholdSeconds = 300}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getInt('token_expiry');

      if (expiry == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeUntilExpiry = expiry - now;

      return timeUntilExpiry <= thresholdSeconds;
    } catch (e) {
      debugPrint('[TokenRefreshService] 检查token过期状态失败: $e');
      return true; // 出错时假设token即将过期
    }
  }

  /// 获取token剩余有效期（秒）
  Future<int?> getTokenRemainingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getInt('token_expiry');

      if (expiry == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiry - now;
    } catch (e) {
      debugPrint('[TokenRefreshService] 获取token剩余时间失败: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    stop();
  }
}

/// Token刷新服务提供者
final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  final authNotifier = ref.watch(authStatusNotifierProvider.notifier);
  return TokenRefreshService(authNotifier);
});

/// Token自动刷新管理器
class TokenRefreshManager {
  static TokenRefreshService? _service;

  /// 初始化并启动token自动刷新
  static void initialize(WidgetRef ref) {
    if (_service != null) {
      debugPrint('[TokenRefreshManager] 服务已初始化，跳过');
      return;
    }

    debugPrint('[TokenRefreshManager] 初始化token自动刷新管理器');
    _service = ref.read(tokenRefreshServiceProvider);
    _service!.start();
  }

  /// 停止token自动刷新
  static void stop() {
    debugPrint('[TokenRefreshManager] 停止token自动刷新管理器');
    _service?.stop();
    _service = null;
  }

  /// 获取服务实例
  static TokenRefreshService? get service => _service;

  /// 手动刷新token
  static Future<bool> manualRefresh() async {
    if (_service == null) {
      debugPrint('[TokenRefreshManager] 服务未初始化，无法手动刷新');
      return false;
    }
    return await _service!.manualRefresh();
  }

  /// 检查token是否即将过期
  static Future<bool> isTokenAboutToExpire({int thresholdSeconds = 300}) async {
    if (_service == null) {
      debugPrint('[TokenRefreshManager] 服务未初始化，无法检查token状态');
      return true; // 未初始化时假设token即将过期
    }
    return await _service!.isTokenAboutToExpire(
      thresholdSeconds: thresholdSeconds,
    );
  }

  /// 获取token剩余时间
  static Future<int?> getTokenRemainingTime() async {
    if (_service == null) {
      debugPrint('[TokenRefreshManager] 服务未初始化，无法获取token剩余时间');
      return null;
    }
    return await _service!.getTokenRemainingTime();
  }
}

/// Token状态提供者（用于UI显示）
final tokenStatusProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>();

  // 定期检查token状态
  Timer.periodic(const Duration(minutes: 1), (_) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final expiry = prefs.getInt('token_expiry');

      if (token == null || token.isEmpty) {
        controller.add('未登录');
        return;
      }

      if (expiry == null) {
        controller.add('已登录（未知有效期）');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeUntilExpiry = expiry - now;

      if (timeUntilExpiry <= 0) {
        controller.add('已登录（Token已过期）');
      } else if (timeUntilExpiry <= 300) {
        controller.add('已登录（Token即将过期，${timeUntilExpiry ~/ 60}分钟后）');
      } else {
        final hours = timeUntilExpiry ~/ 3600;
        final minutes = (timeUntilExpiry % 3600) ~/ 60;
        controller.add('已登录（Token有效，${hours}小时${minutes}分钟后过期）');
      }
    } catch (e) {
      controller.add('Token状态未知');
    }
  });

  // 清理函数
  ref.onDispose(() {
    controller.close();
  });

  return controller.stream;
});
