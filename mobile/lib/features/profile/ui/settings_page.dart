import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/design_system.dart';
import '../../auth/logic/auth_notifier.dart';

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

/// 设置页面
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsNotifierProvider);
    final notifier = ref.read(appSettingsNotifierProvider.notifier);
    final authState = ref.watch(authStateNotifierProvider);

    final darkMode = useState(appSettings['darkMode'] ?? false);
    final notifications = useState(appSettings['notifications'] ?? true);

    void handleLogout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认登出'),
          content: const Text('确定要登出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '登出',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(authStateNotifierProvider.notifier).logout();
        Navigator.pop(context);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 外观设置
          _buildSectionTitle(context, '外观'),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: '暗色模式',
            value: darkMode.value,
            onChanged: (value) {
              darkMode.value = value;
              notifier.setDarkMode(value);
              // TODO: 切换主题
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // 通知设置
          _buildSectionTitle(context, '通知'),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            context,
            icon: Icons.notifications_outlined,
            title: '消息通知',
            value: notifications.value,
            onChanged: (value) {
              notifications.value = value;
              notifier.setNotifications(value);
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // 语言设置
          _buildSectionTitle(context, '语言'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildLanguageOption(
                  context,
                  '简体中文',
                  'zh-CN',
                  appSettings['language'] ?? 'zh-CN',
                  (lang) => notifier.setLanguage(lang),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildLanguageOption(
                  context,
                  'English',
                  'en-US',
                  appSettings['language'] ?? 'zh-CN',
                  (lang) => notifier.setLanguage(lang),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 其他设置
          _buildSectionTitle(context, '其他'),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('隐私政策'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: 打开隐私政策
            },
          ),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('服务条款'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: 打开服务条款
            },
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('关于 Bipupu'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: 打开关于页面
            },
          ),

          const SizedBox(height: AppSpacing.xxl),

          // 清除缓存
          ShadButton.outline(
            onPressed: () {
              // TODO: 清除缓存
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('缓存清除功能开发中')));
            },
            child: const Text('清除缓存'),
          ),

          const SizedBox(height: AppSpacing.md),

          // 退出登录（如果已登录）
          if (authState.isAuthenticated)
            ShadButton.destructive(
              onPressed: handleLogout,
              child: const Text('退出登录'),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String value,
    String selectedValue,
    Function(String) onSelect,
  ) {
    final isSelected = selectedValue == value;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => onSelect(value),
    );
  }
}
