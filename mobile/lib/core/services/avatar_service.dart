import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../config/app_config.dart';

/// 头像服务提供者
final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService();
});

/// 简化的头像服务
///
/// 提供头像URL构建和缓存功能
class AvatarService {
  /// 获取用户头像URL
  ///
  /// [bipupuId] 用户的bipupu_id
  /// [avatarVersion] 头像版本号，用于缓存失效
  /// 返回完整的头像URL
  String getUserAvatarUrl(String bipupuId, {int avatarVersion = 0}) {
    // 添加时间戳参数避免缓存
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url =
        '${AppConfig.baseUrl}/api/profile/avatar/$bipupuId'
        '?v=$avatarVersion&t=$timestamp';
    debugPrint('[AvatarService] 构建头像URL: $url');
    return url;
  }

  /// 获取默认头像URL
  ///
  /// 当用户没有设置头像时使用
  String getDefaultAvatarUrl() {
    return '${AppConfig.baseUrl}/static/default-avatar.png';
  }

  /// 获取服务号头像URL
  ///
  /// [serviceName] 服务号名称
  String getServiceAccountAvatarUrl(String serviceName) {
    final url = '${AppConfig.baseUrl}/api/service-accounts/$serviceName/avatar';
    debugPrint('[AvatarService] 构建服务号头像URL: $url');
    return url;
  }

  /// 检查头像URL是否有效
  ///
  /// 简单的URL格式检查
  bool isValidAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http') || url.startsWith('https');
  }

  /// 获取用户显示头像URL
  ///
  /// 如果用户有自定义头像，返回自定义头像URL
  /// 否则返回默认头像URL
  String getUserDisplayAvatarUrl({
    required String bipupuId,
    String? customAvatarUrl,
    int avatarVersion = 0,
  }) {
    if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
      // 如果自定义头像URL是相对路径，转换为绝对路径
      if (!customAvatarUrl.startsWith('http')) {
        return '${AppConfig.baseUrl}$customAvatarUrl';
      }
      return customAvatarUrl;
    }

    // 使用默认头像URL
    return getUserAvatarUrl(bipupuId, avatarVersion: avatarVersion);
  }
}

/// 头像缓存提供者
///
/// 简单的内存缓存，避免重复请求
final avatarCacheProvider =
    NotifierProvider<AvatarCacheNotifier, Map<String, String>>(
      AvatarCacheNotifier.new,
    );

/// 用户头像URL提供者，用于安全地获取和缓存头像URL
/// 避免在build方法中直接修改provider状态
final userAvatarUrlProvider = Provider.family<String, UserAvatarUrlParams>((
  ref,
  params,
) {
  final avatarService = ref.read(avatarServiceProvider);
  final avatarCache = ref.read(avatarCacheProvider);

  final cachedAvatarKey = params.cacheKey;
  final cachedAvatarUrl = avatarCache[cachedAvatarKey];

  // 如果已经有缓存，直接返回缓存的URL
  if (cachedAvatarUrl != null) {
    return cachedAvatarUrl;
  }

  // 生成新的头像URL
  String avatarUrl;

  if (params.customUrl != null && params.customUrl!.isNotEmpty) {
    // 使用自定义URL
    avatarUrl = params.customUrl!;

    // 如果URL是相对路径，转换为绝对路径
    if (!avatarUrl.startsWith('http')) {
      avatarUrl = '${AppConfig.baseUrl}$avatarUrl';
    }
  } else {
    // 使用API生成的头像URL
    avatarUrl = avatarService.getUserAvatarUrl(
      params.bipupuId,
      avatarVersion: params.avatarVersion,
    );
  }

  // 延迟缓存，避免在build过程中修改provider状态
  Future.delayed(Duration.zero, () {
    if (ref.mounted) {
      ref
          .read(avatarCacheProvider.notifier)
          .cacheAvatar(cachedAvatarKey, avatarUrl);
    }
  });

  return avatarUrl;
});

/// 服务号头像URL提供者，用于安全地获取和缓存服务号头像URL
final serviceAvatarUrlProvider =
    Provider.family<String, ServiceAvatarUrlParams>((ref, params) {
      final avatarService = ref.read(avatarServiceProvider);
      final avatarCache = ref.read(avatarCacheProvider);

      final cachedAvatarKey = params.cacheKey;
      final cachedAvatarUrl = avatarCache[cachedAvatarKey];

      // 如果已经有缓存，直接返回缓存的URL
      if (cachedAvatarUrl != null) {
        return cachedAvatarUrl;
      }

      // 生成新的头像URL
      String avatarUrl;

      if (params.customUrl != null && params.customUrl!.isNotEmpty) {
        // 使用自定义URL
        avatarUrl = params.customUrl!;

        // 如果URL是相对路径，转换为绝对路径
        if (!avatarUrl.startsWith('http')) {
          avatarUrl = '${AppConfig.baseUrl}$avatarUrl';
        }
      } else {
        // 使用API生成的头像URL
        avatarUrl = avatarService.getServiceAccountAvatarUrl(
          params.serviceName,
        );
      }

      // 延迟缓存，避免在build过程中修改provider状态
      Future.delayed(Duration.zero, () {
        if (ref.mounted) {
          ref
              .read(avatarCacheProvider.notifier)
              .cacheAvatar(cachedAvatarKey, avatarUrl);
        }
      });

      return avatarUrl;
    });

/// 用户头像URL参数
class UserAvatarUrlParams {
  final String bipupuId;
  final String cacheKey;
  final String? customUrl;
  final int avatarVersion;

  UserAvatarUrlParams({
    required this.bipupuId,
    required this.cacheKey,
    this.customUrl,
    this.avatarVersion = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserAvatarUrlParams &&
        other.bipupuId == bipupuId &&
        other.cacheKey == cacheKey &&
        other.customUrl == customUrl &&
        other.avatarVersion == avatarVersion;
  }

  @override
  int get hashCode {
    return Object.hash(bipupuId, cacheKey, customUrl, avatarVersion);
  }
}

/// 服务号头像URL参数
class ServiceAvatarUrlParams {
  final String serviceName;
  final String cacheKey;
  final String? customUrl;

  ServiceAvatarUrlParams({
    required this.serviceName,
    required this.cacheKey,
    this.customUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ServiceAvatarUrlParams &&
        other.serviceName == serviceName &&
        other.cacheKey == cacheKey &&
        other.customUrl == customUrl;
  }

  @override
  int get hashCode {
    return Object.hash(serviceName, cacheKey, customUrl);
  }
}

class AvatarCacheNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    return {};
  }

  /// 缓存头像URL
  void cacheAvatar(String key, String url) {
    // 检查是否已经在构建过程中
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // 延迟到下一帧执行
      Future.delayed(Duration.zero, () {
        if (ref.mounted) {
          state = {...state, key: url};
          debugPrint('[AvatarCache] 延迟缓存头像: $key -> $url');
        }
      });
    } else {
      state = {...state, key: url};
      debugPrint('[AvatarCache] 缓存头像: $key -> $url');
    }
  }

  /// 获取缓存的头像URL
  String? getCachedAvatar(String key) {
    final url = state[key];
    if (url != null) {
      debugPrint('[AvatarCache] 命中缓存: $key');
    }
    return url;
  }

  /// 清除指定头像缓存
  void clearAvatarCache(String key) {
    // 检查是否已经在构建过程中
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // 延迟到下一帧执行
      Future.delayed(Duration.zero, () {
        if (ref.mounted) {
          final newState = Map<String, String>.from(state);
          newState.remove(key);
          state = newState;
          debugPrint('[AvatarCache] 延迟清除缓存: $key');
        }
      });
    } else {
      final newState = Map<String, String>.from(state);
      newState.remove(key);
      state = newState;
      debugPrint('[AvatarCache] 清除缓存: $key');
    }
  }

  /// 清除所有头像缓存
  void clearAll() {
    // 检查是否已经在构建过程中
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // 延迟到下一帧执行
      Future.delayed(Duration.zero, () {
        if (ref.mounted) {
          state = {};
          debugPrint('[AvatarCache] 延迟清除所有缓存');
        }
      });
    } else {
      state = {};
      debugPrint('[AvatarCache] 清除所有缓存');
    }
  }

  /// 更新用户头像缓存
  void updateUserAvatarCache(String bipupuId, String avatarUrl) {
    final key = 'user:$bipupuId';
    cacheAvatar(key, avatarUrl);
  }

  /// 获取用户头像缓存
  String? getUserAvatarCache(String bipupuId) {
    final key = 'user:$bipupuId';
    return getCachedAvatar(key);
  }
}
