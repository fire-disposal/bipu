import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../state/user_state.dart';

/// 个人中心 (D) - 头像、ID、菜单卡片式列表
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            appBar: AppBar(title: const Text('我的'), centerTitle: true),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().refreshData(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProfileEditing) {
          return _buildEditingProfile(context, state);
        }

        if (state is ProfileLoaded) {
          return _buildProfileView(context, state);
        }

        return const Scaffold(body: Center(child: Text('未知状态')));
      },
    );
  }

  Widget _buildProfileView(BuildContext context, ProfileLoaded state) {
    final userProfile = state.userProfile;
    final menuItems = state.menuItems;
    final userDevices = state.userDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProfileCubit>().refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProfileCubit>().refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header 区 - 用户信息
              _UserInfoHeader(userProfile: userProfile),

              // 设备信息卡片
              if (userDevices.isNotEmpty) _DeviceInfoCard(devices: userDevices),

              // 菜单卡片
              _MenuCard(menuItems: menuItems),

              // 版本信息
              _VersionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditingProfile(BuildContext context, ProfileEditing state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: state.hasChanges
                ? () => context.read<ProfileCubit>().saveEditedProfile()
                : null,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 头像编辑
            _AvatarEditor(
              currentAvatar: state.editedProfile.avatarUrl,
              onAvatarChanged: (newAvatar) {
                final updatedProfile = state.editedProfile.copyWith(
                  avatarUrl: newAvatar,
                );
                context.read<ProfileCubit>().updateEditingProfile(
                  updatedProfile,
                );
              },
            ),
            const SizedBox(height: 24),

            // 昵称编辑
            _TextFieldEditor(
              label: '昵称',
              value: state.editedProfile.nickname,
              onChanged: (value) {
                final updatedProfile = state.editedProfile.copyWith(
                  nickname: value,
                );
                context.read<ProfileCubit>().updateEditingProfile(
                  updatedProfile,
                );
              },
            ),

            // 邮箱编辑
            _TextFieldEditor(
              label: '邮箱',
              value: state.editedProfile.email,
              onChanged: (value) {
                final updatedProfile = state.editedProfile.copyWith(
                  email: value,
                );
                context.read<ProfileCubit>().updateEditingProfile(
                  updatedProfile,
                );
              },
            ),

            // 生日编辑
            if (state.editedProfile.birthDate != null)
              _DateFieldEditor(
                label: '生日',
                value: state.editedProfile.birthDate!,
                onChanged: (value) {
                  final updatedProfile = state.editedProfile.copyWith(
                    birthDate: value,
                  );
                  context.read<ProfileCubit>().updateEditingProfile(
                    updatedProfile,
                  );
                },
              ),

            const Spacer(),

            // 取消按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.read<ProfileCubit>().cancelEditing(),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认注销'),
        content: const Text('确定要注销登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileCubit>().logout();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 用户信息头部组件
class _UserInfoHeader extends StatelessWidget {
  final dynamic userProfile;

  const _UserInfoHeader({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[100],
            backgroundImage: userProfile.avatarUrl != null
                ? NetworkImage(userProfile.avatarUrl!)
                : null,
            child: userProfile.avatarUrl == null
                ? const Icon(Icons.person, size: 48, color: Colors.blue)
                : null,
          ),
          const SizedBox(width: 20),

          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.nickname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${userProfile.id}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (userProfile.constellation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '星座: ${userProfile.constellation}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                if (userProfile.mbti != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'MBTI: ${userProfile.mbti}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.read<ProfileCubit>().handleMenuItemClick('profile'),
          ),
        ],
      ),
    );
  }
}

/// 设备信息卡片组件
class _DeviceInfoCard extends StatelessWidget {
  final List<dynamic> devices;

  const _DeviceInfoCard({required this.devices});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.devices, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '我的设备',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<ProfileCubit>().handleMenuItemClick('devices'),
                child: const Text('管理'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...devices.map((device) => _DeviceItem(device: device)),
        ],
      ),
    );
  }
}

/// 设备项组件
class _DeviceItem extends StatelessWidget {
  final dynamic device;

  const _DeviceItem({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: device.isConnected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  device.isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    fontSize: 12,
                    color: device.isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (device.batteryLevel != null) ...[
            Icon(
              _getBatteryIcon(device.batteryLevel!),
              color: _getBatteryColor(device.batteryLevel!),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${device.batteryLevel}%',
              style: TextStyle(
                fontSize: 12,
                color: _getBatteryColor(device.batteryLevel!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 20) return Colors.green;
    return Colors.red;
  }
}

/// 菜单卡片组件
class _MenuCard extends StatelessWidget {
  final List<dynamic> menuItems;

  const _MenuCard({required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: menuItems
            .map((menuItem) => _MenuItem(menuItem: menuItem))
            .toList(),
      ),
    );
  }
}

/// 菜单项组件
class _MenuItem extends StatelessWidget {
  final dynamic menuItem;

  const _MenuItem({required this.menuItem});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(menuItem.icon, color: Colors.blue[700]),
      title: Text(menuItem.title),
      subtitle: menuItem.subtitle != null ? Text(menuItem.subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (menuItem.hasNotification && menuItem.notificationCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                menuItem.notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () =>
          context.read<ProfileCubit>().handleMenuItemClick(menuItem.id),
    );
  }
}

/// 版本信息组件
class _VersionInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'BiPuPu v1.0.0',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

/// 头像编辑器组件
class _AvatarEditor extends StatelessWidget {
  final String? currentAvatar;
  final Function(String?) onAvatarChanged;

  const _AvatarEditor({
    required this.currentAvatar,
    required this.onAvatarChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue[100],
            backgroundImage: currentAvatar != null
                ? NetworkImage(currentAvatar!)
                : null,
            child: currentAvatar == null
                ? const Icon(Icons.person, size: 60, color: Colors.blue)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  // 实现头像选择功能
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('头像选择功能开发中')));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 文本字段编辑器组件
class _TextFieldEditor extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _TextFieldEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }
}

/// 日期字段编辑器组件
class _DateFieldEditor extends StatelessWidget {
  final String label;
  final DateTime value;
  final Function(DateTime) onChanged;

  const _DateFieldEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
