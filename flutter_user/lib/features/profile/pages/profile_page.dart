import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final username = user?.username ?? "Guest";
    final email = user?.email ?? "Offline Mode";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // Device Binding Section
              _buildSectionHeader('Device Management'),
              _buildSettingItem(
                context,
                icon: Icons.bluetooth_connected,
                title: 'Machine Binding',
                subtitle: 'Manage connected pagers',
                onTap: () => context.push('/bluetooth'),
              ),

              const SizedBox(height: 20),
              // Account & Security
              _buildSectionHeader('Account & Security'),
              _buildSettingItem(
                context,
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: () => context.push('/profile/personal_info'),
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: 'Account Security',
                subtitle: 'Password, 2FA',
                onTap: () => context.push('/profile/security'),
              ),
              _buildSettingItem(
                context,
                icon: Icons.lock_outline,
                title: 'Privacy Settings',
                onTap: () => context.push('/profile/privacy'),
              ),

              const SizedBox(height: 20),
              // App Settings
              _buildSectionHeader('Settings'),
              _buildSettingItem(
                context,
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Light, Dark, System',
                onTap: () => _showThemeSelector(context),
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () => context.push('/profile/notifications'),
              ),
              _buildSettingItem(
                context,
                icon: Icons.language,
                title: 'Language',
                onTap: () => context.push('/profile/language'),
              ),
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: 'About Bipupu',
                onTap: () => context.push('/profile/about'),
              ),

              const SizedBox(height: 20),
              _buildSettingItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Bipupu v1.0.1',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: ThemeService(),
                builder: (context, _) {
                  final currentMode = ThemeService().themeMode;
                  return Column(
                    children: [
                      _buildThemeOption(
                        context,
                        title: 'Device System',
                        mode: ThemeMode.system,
                        groupValue: currentMode,
                      ),
                      _buildThemeOption(
                        context,
                        title: 'Light Mode',
                        mode: ThemeMode.light,
                        groupValue: currentMode,
                      ),
                      _buildThemeOption(
                        context,
                        title: 'Dark Mode',
                        mode: ThemeMode.dark,
                        groupValue: currentMode,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required ThemeMode mode,
    required ThemeMode groupValue,
  }) {
    final isSelected = mode == groupValue;
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        ThemeService().updateThemeMode(mode);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = Colors.grey,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}
