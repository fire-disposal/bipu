import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/core/network/rest_client.dart';
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
                  icon: Icons.notifications_active,
                  label: 'Notifications',
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
                    color: sidebarTextColor.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: sidebarTextColor.withValues(alpha: 0.7),
                    ),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                    : textColor.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? selectedTextColor
                      : textColor.withValues(alpha: 0.7),
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
        return 'System Notifications';
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

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  RestClient get _api => bipupuApi;

  bool _isLoading = true;
  Map<String, dynamic> _healthStatus = {};
  Map<String, dynamic> _notificationStats = {};
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final health = await _api.checkHealth();
      final stats = await _api.adminGetSystemNotificationStats();
      // Fetch user count loosely via page 1
      final users = await _api.adminGetAllUsers(page: 1, size: 1);

      if (mounted) {
        setState(() {
          _healthStatus = health;
          _notificationStats = stats;
          _totalUsers = users.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // KPIs
          Row(
            children: [
              _buildKpiCard(
                'Total Users',
                _totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Notifications',
                (_notificationStats['total'] ?? 0).toString(),
                Icons.notifications,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Read Rate',
                '${((_notificationStats['read_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
                Icons.visibility,
                Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // System Health
          const Text(
            'System Health',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHealthRow(
                    'API Service',
                    _healthStatus['status'] == 'healthy',
                  ),
                  const Divider(),
                  _buildHealthRow(
                    'Database',
                    _healthStatus['database'] == 'connected',
                  ),
                  const Divider(),
                  _buildHealthRow(
                    'Redis',
                    _healthStatus['redis'] == 'connected',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthRow(String service, bool isHealthy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(service, style: const TextStyle(fontSize: 16)),
        Chip(
          label: Text(isHealthy ? 'Operational' : 'Issues'),
          backgroundColor: isHealthy ? Colors.green[100] : Colors.red[100],
          labelStyle: TextStyle(
            color: isHealthy ? Colors.green[800] : Colors.red[800],
          ),
        ),
      ],
    );
  }
}
