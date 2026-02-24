import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/logic/auth_notifier.dart';

/// 个人设置项
class SettingItem {
  final String id;
  final String title;
  final String? description;
  final IconData icon;
  final bool requiresAuth;

  SettingItem({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    this.requiresAuth = true,
  });
}

/// 个人资料提供者
final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>(
      () => ProfileNotifier(),
    );

class ProfileNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    // 初始化时加载用户资料
    _loadUserProfile();
    return const AsyncValue.data(null);
  }

  /// 加载用户资料
  Future<UserModel?> _loadUserProfile() async {
    final authStatus = ref.read(authStatusNotifierProvider);
    if (authStatus != AuthStatus.authenticated) {
      return null;
    }

    try {
      final authNotifier = ref.read(authStatusNotifierProvider.notifier);
      return await authNotifier.getCurrentUser();
    } catch (e) {
      debugPrint('[Profile] 加载用户资料失败：$e');
      return null;
    }
  }

  /// 刷新用户资料
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadUserProfile());
  }

  /// 更新用户资料
  Future<bool> updateProfile({
    String? nickname,
    Map<String, dynamic>? cosmicProfile,
  }) async {
    try {
      debugPrint('[Profile] 更新用户资料：nickname=$nickname');

      final restClient = ref.read(restClientProvider);
      final updateData = <String, dynamic>{};

      if (nickname != null) {
        updateData['nickname'] = nickname;
      }
      if (cosmicProfile != null) {
        updateData['cosmic_profile'] = cosmicProfile;
      }

      if (updateData.isEmpty) {
        debugPrint('[Profile] 没有需要更新的数据');
        return true;
      }

      final response = await restClient.updateUserProfile(updateData);

      if (response.response.statusCode == 200) {
        debugPrint('[Profile] 用户资料更新成功');
        await refresh();
        return true;
      } else {
        debugPrint('[Profile] 用户资料更新失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Profile] 更新用户资料失败：$e');
      return false;
    }
  }

  /// 更新头像
  Future<bool> updateAvatar(String avatarUrl) async {
    try {
      // TODO: 调用 API 更新头像
      debugPrint('[Profile] 更新头像：$avatarUrl');
      await refresh();
      return true;
    } catch (e) {
      debugPrint('[Profile] 更新头像失败：$e');
      return false;
    }
  }

  /// 更新密码
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      debugPrint('[Profile] 更新密码');

      final restClient = ref.read(restClientProvider);
      final response = await restClient.updatePassword({
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      if (response.response.statusCode == 200) {
        debugPrint('[Profile] 密码更新成功');
        return true;
      } else {
        debugPrint('[Profile] 密码更新失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Profile] 更新密码失败：$e');
      return false;
    }
  }

  /// 更新时区
  Future<bool> updateTimezone(String timezone) async {
    try {
      debugPrint('[Profile] 更新时区：$timezone');

      final restClient = ref.read(restClientProvider);
      final response = await restClient.updateTimezone({'timezone': timezone});

      if (response.response.statusCode == 200) {
        debugPrint('[Profile] 时区更新成功');
        return true;
      } else {
        debugPrint('[Profile] 时区更新失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Profile] 更新时区失败：$e');
      return false;
    }
  }
}

/// 应用设置提供者（本地存储）
final appSettingsNotifierProvider =
    NotifierProvider<AppSettingsNotifier, Map<String, dynamic>>(
      () => AppSettingsNotifier(),
    );

class AppSettingsNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    _loadSettings();
    return {'darkMode': false, 'notifications': true, 'language': 'zh-CN'};
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = {
        'darkMode': prefs.getBool('dark_mode') ?? false,
        'notifications': prefs.getBool('notifications') ?? true,
        'language': prefs.getString('language') ?? 'zh-CN',
      };
    } catch (e) {
      debugPrint('[AppSettings] 加载设置失败：$e');
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
    state = {...state, 'darkMode': enabled};
  }

  Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', enabled);
    state = {...state, 'notifications': enabled};
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    state = {...state, 'language': language};
  }
}

/// 设置项列表
final settingsListProvider = Provider<List<SettingItem>>((ref) {
  return [
    SettingItem(id: 'profile', title: '个人资料', icon: Icons.person_outline),
    SettingItem(id: 'security', title: '账号安全', icon: Icons.security),
    SettingItem(
      id: 'notifications',
      title: '通知设置',
      icon: Icons.notifications_outlined,
      requiresAuth: false,
    ),
    SettingItem(id: 'privacy', title: '隐私设置', icon: Icons.lock_outline),
    SettingItem(
      id: 'appearance',
      title: '外观设置',
      icon: Icons.palette_outlined,
      requiresAuth: false,
    ),
    SettingItem(
      id: 'about',
      title: '关于',
      icon: Icons.info_outline,
      requiresAuth: false,
    ),
  ];
});
