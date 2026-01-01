import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

/// Admin Shell Page - 提供侧边栏导航框架
class AdminShellPage extends StatelessWidget {
  final Widget child;

  const AdminShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sidebar colors
    final sidebarColor = isDark ? colorScheme.surface : const Color(0xFF2C3E50);
    final sidebarHeaderColor = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFF1A252F);
    final sidebarTextColor = isDark ? colorScheme.onSurface : Colors.white;
    final sidebarSelectedColor = isDark
        ? colorScheme.primaryContainer
        : const Color(0xFF34495E);
    final sidebarSelectedTextColor = isDark
        ? colorScheme.onPrimaryContainer
        : Colors.white;

    return Scaffold(
      body: Row(
        children: [
          // Classic Sidebar
          Container(
            width: 250,
            color: sidebarColor,
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  color: sidebarHeaderColor,
                  child: Text(
                    'Bipupu Admin',
                    style: TextStyle(
                      color: sidebarTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Menu Items
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                  selectedIndex: selectedIndex,
                  path: '/dashboard',
                  textColor: sidebarTextColor,
                  selectedColor: sidebarSelectedColor,
                  selectedTextColor: sidebarSelectedTextColor,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  label: 'User Management',
                  index: 1,
                  selectedIndex: selectedIndex,
                  path: '/users',
                  textColor: sidebarTextColor,
                  selectedColor: sidebarSelectedColor,
                  selectedTextColor: sidebarSelectedTextColor,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  label: 'System Logs',
                  index: 2,
                  selectedIndex: selectedIndex,
                  path: '/logs',
                  textColor: sidebarTextColor,
                  selectedColor: sidebarSelectedColor,
                  selectedTextColor: sidebarSelectedTextColor,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.message,
                  label: 'Messages',
                  index: 3,
                  selectedIndex: selectedIndex,
                  path: '/messages',
                  textColor: sidebarTextColor,
                  selectedColor: sidebarSelectedColor,
                  selectedTextColor: sidebarSelectedTextColor,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.subscriptions,
                  label: 'Subscriptions',
                  index: 4,
                  selectedIndex: selectedIndex,
                  path: '/subscriptions',
                  textColor: sidebarTextColor,
                  selectedColor: sidebarSelectedColor,
                  selectedTextColor: sidebarSelectedTextColor,
                ),
                const Divider(color: Colors.white24),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 5,
                  selectedIndex: selectedIndex,
                  path: '/settings',
                  textColor: sidebarTextColor,
                  selectedColor: sidebarSelectedColor,
                  selectedTextColor: sidebarSelectedTextColor,
                ),
                const Spacer(),
                // Logout Button
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: sidebarTextColor.withOpacity(0.7),
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: sidebarTextColor.withOpacity(0.7)),
                  ),
                  onTap: () => AuthService().logout(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPageTitle(selectedIndex),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Page Content
                Expanded(
                  child: Container(
                    color: isDark
                        ? colorScheme.surfaceContainerLow
                        : const Color(0xFFF5F6FA),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required int selectedIndex,
    required String path,
    required Color textColor,
    required Color selectedColor,
    required Color selectedTextColor,
  }) {
    final isSelected = index == selectedIndex;
    return Material(
      color: isSelected ? selectedColor : Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? selectedTextColor
                    : textColor.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? selectedTextColor
                      : textColor.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'System Logs';
      case 3:
        return 'Message Management';
      case 4:
        return 'Subscription Management';
      case 5:
        return 'Settings';
      default:
        return 'Admin';
    }
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/users')) return 1;
    if (location.startsWith('/logs')) return 2;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/subscriptions')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Admin Panel',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('System Status'),
                  SizedBox(height: 10),
                  Text('All systems operational'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
