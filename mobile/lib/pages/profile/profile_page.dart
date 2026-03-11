import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/bluetooth_device_service.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/widgets/user_avatar.dart';

/// 个人档案页面 - 优化版
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    // 监听用户状态变化
    _authService.authState.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.authState.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  /// 刷新用户信息
  Future<void> _refreshUserInfo() async {
    try {
      await _authService.fetchCurrentUser();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[ProfilePage] 刷新用户信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final username = user?.nickname ?? user?.username ?? 'not_logged_in'.tr();
    final bipupuId = user?.bipupuId ?? '';
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refreshUserInfo,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 用户信息头部
          SliverToBoxAdapter(
            child: _buildUserHeader(context, user, username, bipupuId, cs),
          ),

          // 快捷信息卡片（已隐藏，主页面不再展开显示用户详细信息）

          // 设置列表
          SliverToBoxAdapter(child: _buildSettingsSection(context, cs)),

          // 底部版本号
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Bipupu v1.0.1',
                  style: TextStyle(color: cs.outline, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 用户头部信息
  Widget _buildUserHeader(
    BuildContext context,
    dynamic user,
    String username,
    String bipupuId,
    ColorScheme cs,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? cs.surface : cs.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // 头像
          GestureDetector(
            onTap: () => _navigateToEditProfile(context),
            child: Hero(
              tag: 'user_avatar',
              child: UserAvatar(
                bipupuId: user?.bipupuId,
                displayName: user?.nickname ?? user?.username ?? '?',
                radius: 40,
                backgroundColor: cs.primaryContainer,
                fallbackIcon: Icon(Icons.person, size: 40, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 用户名和ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (bipupuId.isNotEmpty)
                  GestureDetector(
                    onTap: () => _copyBipupuId(context, bipupuId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID: $bipupuId',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded, size: 14, color: cs.outline),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 编辑按钮
          IconButton(
            onPressed: () => _navigateToEditProfile(context),
            icon: Icon(Icons.edit_rounded, color: cs.onSurfaceVariant),
            tooltip: 'edit_profile'.tr(),
          ),
        ],
      ),
    );
  }

  /// 快捷信息卡片
  Widget _buildQuickInfoCard(
    BuildContext context,
    dynamic user,
    ColorScheme cs,
  ) {
    final birthday = user?.birthday;
    final gender = user?.gender;
    final mbti = user?.mbti;

    // 没有任何额外信息时不显示卡片
    if (birthday == null && gender == null && mbti == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (birthday != null)
                _buildQuickInfoItem(
                  context,
                  Icons.cake_outlined,
                  _formatBirthday(birthday),
                  'birthday'.tr(),
                  cs,
                ),
              if (gender != null)
                _buildQuickInfoItem(
                  context,
                  _getGenderIcon(gender.toString()),
                  _getGenderText(gender.toString()),
                  'gender'.tr(),
                  cs,
                ),
              if (mbti != null && mbti.toString().isNotEmpty)
                _buildQuickInfoItem(
                  context,
                  Icons.psychology_outlined,
                  mbti.toString().toUpperCase(),
                  'mbti_type'.tr(),
                  cs,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
            fontSize: 14,
          ),
        ),
        Text(label, style: TextStyle(color: cs.outline, fontSize: 11)),
      ],
    );
  }

  /// 设置部分
  Widget _buildSettingsSection(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 账户管理
          _buildSectionTitle('account_management'.tr(), cs),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'personal_profile'.tr(),
                  subtitle: 'edit_profile'.tr(),
                  onTap: () => _navigateToEditProfile(context),
                  cs: cs,
                ),
                _buildDivider(cs),
                _buildSettingsTile(
                  context,
                  icon: Icons.security_rounded,
                  title: 'account_security'.tr(),
                  subtitle: 'change_password'.tr(),
                  onTap: () => context.push('/profile/security'),
                  cs: cs,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 应用设置
          _buildSectionTitle('app_settings'.tr(), cs),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.language_rounded,
                  title: 'language'.tr(),
                  subtitle: _getCurrentLanguageName(context),
                  onTap: () => context.push('/profile/language'),
                  cs: cs,
                ),
                _buildDivider(cs),
                _buildSettingsTile(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  title: 'clear_cache'.tr(),
                  subtitle: 'clear_local_data'.tr(),
                  onTap: () => _showClearCacheDialog(context),
                  cs: cs,
                ),
                _buildDivider(cs),
                _buildSettingsTile(
                  context,
                  icon: Icons.link_off_rounded,
                  title: 'clear_binding'.tr(),
                  subtitle: 'clear_bluetooth_binding'.tr(),
                  onTap: () => _showClearBindingDialog(context),
                  cs: cs,
                ),
                _buildDivider(cs),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'about'.tr(),
                  subtitle: 'app_version_info'.tr(),
                  onTap: () => context.push('/profile/about'),
                  cs: cs,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 退出登录
          Card(
            elevation: 0,
            color: cs.errorContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildSettingsTile(
              context,
              icon: Icons.logout_rounded,
              title: 'logout'.tr(),
              subtitle: null,
              onTap: () => _showLogoutDialog(context),
              cs: cs,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.outline,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required ColorScheme cs,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? cs.error : cs.primary;
    final textColor = isDestructive ? cs.error : cs.onSurface;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: cs.outline))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }

  // ─── 辅助方法 ───────────────────────────────────────

  void _navigateToEditProfile(BuildContext context) {
    context.push('/profile/edit_profile').then((_) {
      // 返回时刷新用户信息
      _refreshUserInfo();
    });
  }

  void _copyBipupuId(BuildContext context, String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('copied_bipupu_id'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatBirthday(DateTime date) {
    return '${date.month}/${date.day}';
  }

  IconData _getGenderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return Icons.transgender_rounded;
    }
  }

  String _getGenderText(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'gender_male'.tr();
      case 'female':
        return 'gender_female'.tr();
      default:
        return 'gender_other'.tr();
    }
  }

  String _getCurrentLanguageName(BuildContext context) {
    final locale = context.locale;
    if (locale.languageCode == 'zh') {
      return '简体中文';
    }
    return 'English';
  }

  // ─── 对话框 ───────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('confirm_logout'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (context.mounted) context.go('/login');
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_local_cache'.tr()),
        content: Text('confirm_clear_cache'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Hive.deleteFromDisk();
                await Hive.initFlutter();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('local_cache_cleared'.tr()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'clear_cache_failed'.tr(args: [e.toString()]),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _showClearBindingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_binding'.tr()),
        content: Text('confirm_clear_binding'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final bluetoothService = BluetoothDeviceService();
                await bluetoothService.clearBinding();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('binding_cleared'.tr()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'clear_binding_failed'.tr(args: [e.toString()]),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );
  }
}
