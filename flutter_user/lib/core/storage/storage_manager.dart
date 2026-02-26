import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 高性能存储管理器
class StorageManager {
  static const String _cacheBoxName = 'cache_box';
  static const String _userDataBoxName = 'user_data_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _tempBoxName = 'temp_box';

  // 缓存配置
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  static const int _maxItemsPerBox = 1000;

  // 安全存储实例
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      sharedPreferencesName: 'bipupu_secure_prefs',
      preferencesKeyPrefix: 'bipupu_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.bipupu.user',
      accountName: 'bipupu_keychain',
    ),
  );

  // 存储盒子缓存
  static final Map<String, Box> _boxCache = {};
  static final Map<String, Timer> _cleanupTimers = {};

  /// 初始化存储系统
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // 预加载常用存储盒子
      await _preloadBoxes();

      // 清理旧版本可能遗留的 guest_mode 键（迁移步骤）
      try {
        final tokenBox = await Hive.openBox<String>('token_box');
        if (tokenBox.containsKey('guest_mode')) {
          await tokenBox.delete('guest_mode');
          debugPrint('Removed legacy guest_mode key from token_box');
        }
      } catch (e) {
        debugPrint('Error cleaning legacy guest_mode key: $e');
      }

      // 设置定期清理
      _schedulePeriodicCleanup();

      debugPrint('StorageManager initialized successfully');
    } catch (e) {
      debugPrint('StorageManager initialization error: $e');
      rethrow;
    }
  }

  /// 预加载存储盒子
  static Future<void> _preloadBoxes() async {
    final boxNames = [_cacheBoxName, _userDataBoxName, _settingsBoxName];

    for (final boxName in boxNames) {
      try {
        final box = await Hive.openBox(boxName);
        _boxCache[boxName] = box;
      } catch (e) {
        debugPrint('Error opening box $boxName: $e');
      }
    }
  }

  /// 获取存储盒子
  static Future<Box> _getBox(String boxName) async {
    if (_boxCache.containsKey(boxName)) {
      return _boxCache[boxName]!;
    }

    try {
      final box = await Hive.openBox(boxName);
      _boxCache[boxName] = box;
      return box;
    } catch (e) {
      debugPrint('Error getting box $boxName: $e');
      rethrow;
    }
  }

  /// 缓存数据存储
  static Future<void> setCache<T>(
    String key,
    T data, {
    Duration? duration,
    String? category,
  }) async {
    try {
      final box = await _getBox(_cacheBoxName);

      final cacheItem = CacheItem<T>(
        data: data,
        timestamp: DateTime.now(),
        expiry: DateTime.now().add(duration ?? _defaultCacheDuration),
        category: category,
      );

      await box.put(key, cacheItem.toJson());

      // 检查缓存大小并清理
      _checkCacheSize();
    } catch (e) {
      debugPrint('Error setting cache for key $key: $e');
    }
  }

  /// 获取缓存数据
  static Future<T?> getCache<T>(String key) async {
    try {
      final box = await _getBox(_cacheBoxName);
      final jsonData = box.get(key);

      if (jsonData == null) return null;

      final cacheItem = CacheItem.fromJson<T>(jsonData);

      // 检查是否过期
      if (cacheItem.isExpired) {
        await box.delete(key);
        return null;
      }

      return cacheItem.data;
    } catch (e) {
      debugPrint('Error getting cache for key $key: $e');
      return null;
    }
  }

  /// 批量缓存操作
  static Future<void> setBatchCache<T>(
    Map<String, T> data, {
    Duration? duration,
    String? category,
  }) async {
    try {
      final box = await _getBox(_cacheBoxName);
      final Map<String, dynamic> batchData = {};

      final expiry = DateTime.now().add(duration ?? _defaultCacheDuration);

      for (final entry in data.entries) {
        final cacheItem = CacheItem<T>(
          data: entry.value,
          timestamp: DateTime.now(),
          expiry: expiry,
          category: category,
        );
        batchData[entry.key] = cacheItem.toJson();
      }

      await box.putAll(batchData);
      _checkCacheSize();
    } catch (e) {
      debugPrint('Error setting batch cache: $e');
    }
  }

  /// 用户数据存储
  static Future<void> setUserData<T>(String key, T data) async {
    try {
      final box = await _getBox(_userDataBoxName);
      await box.put(key, json.encode(data));
    } catch (e) {
      debugPrint('Error setting user data for key $key: $e');
    }
  }

  /// 获取用户数据
  static Future<T?> getUserData<T>(String key) async {
    try {
      final box = await _getBox(_userDataBoxName);
      final jsonString = box.get(key);

      if (jsonString == null) return null;
      return json.decode(jsonString) as T;
    } catch (e) {
      debugPrint('Error getting user data for key $key: $e');
      return null;
    }
  }

  /// 安全存储（用于敏感数据）
  static Future<void> setSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error setting secure data for key $key: $e');
    }
  }

  /// 获取安全数据
  static Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Error getting secure data for key $key: $e');
      return null;
    }
  }

  /// 设置配置数据
  static Future<void> setSetting<T>(String key, T value) async {
    try {
      final box = await _getBox(_settingsBoxName);
      await box.put(key, value);
    } catch (e) {
      debugPrint('Error setting configuration for key $key: $e');
    }
  }

  /// 获取配置数据
  static Future<T?> getSetting<T>(String key, [T? defaultValue]) async {
    try {
      final box = await _getBox(_settingsBoxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('Error getting configuration for key $key: $e');
      return defaultValue;
    }
  }

  /// 临时存储（应用重启后清除）
  static Future<void> setTemp<T>(
    String key,
    T data, {
    Duration? duration,
  }) async {
    try {
      final box = await _getBox(_tempBoxName);
      await box.put(key, data);

      // 设置自动清理
      if (duration != null) {
        _cleanupTimers[key]?.cancel();
        _cleanupTimers[key] = Timer(duration, () async {
          await box.delete(key);
          _cleanupTimers.remove(key);
        });
      }
    } catch (e) {
      debugPrint('Error setting temp data for key $key: $e');
    }
  }

  /// 获取临时数据
  static Future<T?> getTemp<T>(String key) async {
    try {
      final box = await _getBox(_tempBoxName);
      return box.get(key) as T?;
    } catch (e) {
      debugPrint('Error getting temp data for key $key: $e');
      return null;
    }
  }

  /// 清理过期缓存
  static Future<void> cleanExpiredCache() async {
    try {
      final box = await _getBox(_cacheBoxName);
      final keysToDelete = <String>[];

      for (final key in box.keys) {
        try {
          final jsonData = box.get(key);
          if (jsonData != null) {
            final cacheItem = CacheItem.fromJson<dynamic>(jsonData);
            if (cacheItem.isExpired) {
              keysToDelete.add(key as String);
            }
          }
        } catch (e) {
          // 如果无法解析，也删除
          keysToDelete.add(key as String);
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      debugPrint('Cleaned ${keysToDelete.length} expired cache items');
    } catch (e) {
      debugPrint('Error cleaning expired cache: $e');
    }
  }

  /// 检查并管理缓存大小
  static Future<void> _checkCacheSize() async {
    try {
      final box = await _getBox(_cacheBoxName);

      if (box.length > _maxItemsPerBox) {
        // 删除最旧的项目
        final keys = box.keys.toList();
        final itemsToDelete = keys.take(keys.length - _maxItemsPerBox + 100);

        for (final key in itemsToDelete) {
          await box.delete(key);
        }

        debugPrint(
          'Cache size management: removed ${itemsToDelete.length} items',
        );
      }
    } catch (e) {
      debugPrint('Error checking cache size: $e');
    }
  }

  /// 设置定期清理
  static void _schedulePeriodicCleanup() {
    Timer.periodic(const Duration(hours: 6), (timer) async {
      await cleanExpiredCache();
      await _clearTempStorage();
    });
  }

  /// 清理临时存储
  static Future<void> _clearTempStorage() async {
    try {
      final box = await _getBox(_tempBoxName);
      await box.clear();

      // 取消所有清理定时器
      for (final timer in _cleanupTimers.values) {
        timer.cancel();
      }
      _cleanupTimers.clear();

      debugPrint('Temp storage cleared');
    } catch (e) {
      debugPrint('Error clearing temp storage: $e');
    }
  }

  /// 获取存储统计信息
  static Future<StorageStats> getStorageStats() async {
    try {
      final cacheBox = await _getBox(_cacheBoxName);
      final userDataBox = await _getBox(_userDataBoxName);
      final settingsBox = await _getBox(_settingsBoxName);
      final tempBox = await _getBox(_tempBoxName);

      return StorageStats(
        cacheItems: cacheBox.length,
        userDataItems: userDataBox.length,
        settingsItems: settingsBox.length,
        tempItems: tempBox.length,
        totalItems:
            cacheBox.length +
            userDataBox.length +
            settingsBox.length +
            tempBox.length,
      );
    } catch (e) {
      debugPrint('Error getting storage stats: $e');
      return const StorageStats();
    }
  }

  /// 清理所有数据
  static Future<void> clearAllData() async {
    try {
      for (final box in _boxCache.values) {
        await box.clear();
      }

      await _secureStorage.deleteAll();

      // 取消所有定时器
      for (final timer in _cleanupTimers.values) {
        timer.cancel();
      }
      _cleanupTimers.clear();

      debugPrint('All data cleared');
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }

  /// 关闭存储系统
  static Future<void> dispose() async {
    try {
      for (final timer in _cleanupTimers.values) {
        timer.cancel();
      }
      _cleanupTimers.clear();

      for (final box in _boxCache.values) {
        await box.close();
      }
      _boxCache.clear();

      debugPrint('StorageManager disposed');
    } catch (e) {
      debugPrint('Error disposing StorageManager: $e');
    }
  }
}

/// 缓存项目模型
class CacheItem<T> {
  final T data;
  final DateTime timestamp;
  final DateTime expiry;
  final String? category;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.expiry,
    this.category,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expiry': expiry.toIso8601String(),
      'category': category,
    };
  }

  static CacheItem<T> fromJson<T>(Map<dynamic, dynamic> json) {
    return CacheItem<T>(
      data: json['data'] as T,
      timestamp: DateTime.parse(json['timestamp']),
      expiry: DateTime.parse(json['expiry']),
      category: json['category'] as String?,
    );
  }
}

/// 存储统计信息
class StorageStats {
  final int cacheItems;
  final int userDataItems;
  final int settingsItems;
  final int tempItems;
  final int totalItems;

  const StorageStats({
    this.cacheItems = 0,
    this.userDataItems = 0,
    this.settingsItems = 0,
    this.tempItems = 0,
    this.totalItems = 0,
  });

  @override
  String toString() {
    return 'StorageStats(cache: $cacheItems, userData: $userDataItems, '
        'settings: $settingsItems, temp: $tempItems, total: $totalItems)';
  }
}

/// 存储键常量
class StorageKeys {
  // 用户相关
  static const String userProfile = 'user_profile';
  static const String userPreferences = 'user_preferences';
  static const String userSettings = 'user_settings';

  // 缓存相关
  static const String apiCache = 'api_cache_';
  static const String imageCache = 'image_cache_';
  static const String chatMessages = 'chat_messages_';

  // 配置相关
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String fontSize = 'font_size';
  static const String notificationEnabled = 'notification_enabled';

  // 临时数据
  static const String tempUpload = 'temp_upload_';
  static const String tempDownload = 'temp_download_';

  // 安全数据
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String biometricKey = 'biometric_key';
}
