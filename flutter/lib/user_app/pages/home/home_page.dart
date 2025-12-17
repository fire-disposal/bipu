import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bipupu_flutter/core/utils/logger.dart';
import 'package:bipupu_flutter/core/utils/constants.dart';
import 'package:bipupu_flutter/user_app/widgets/bottom_navigation.dart';
import 'package:bipupu_flutter/user_app/pages/message/message_list_page.dart';
import 'package:bipupu_flutter/user_app/pages/device/device_scan_page.dart';
import 'package:bipupu_flutter/user_app/pages/profile/profile_home_page.dart';
import 'package:bipupu_flutter/user_app/state/user_data_cubit.dart'
    as user_data;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Logger.info('进入主页');
    // 加载用户数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<user_data.UserDataCubit>().loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: UserBottomNavigation(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      // 已移除UserFloatingActionButton
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const _HomeTab();
      case 1:
        return const MessageListPage();
      case 2:
        return const DeviceScanPage();
      case 3:
        return const ProfileHomePage();
      default:
        return const _HomeTab();
    }
  }
}

// 首页标签页
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Bipupu'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // 跳转到通知页面
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child:
                BlocBuilder<user_data.UserDataCubit, user_data.UserDataState>(
                  builder: (context, state) {
                    if (state is user_data.UserDataLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is user_data.UserDataError) {
                      return Center(child: Text('加载失败: ${state.message}'));
                    }

                    if (state is user_data.UserDataLoaded) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDailyFortuneCard(context, state),
                          const SizedBox(height: 24),
                          _buildQuickActions(context, state),
                          const SizedBox(height: 24),
                          _buildRecentMessages(context, state),
                          const SizedBox(height: 24),
                          _buildConnectedDevice(context, state),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyFortuneCard(
    BuildContext context,
    user_data.UserDataLoaded state,
  ) {
    final fortune = state.dailyFortune ?? '今日运势加载中...';

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/daily-fortune');
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日运势',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fortune,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withAlpha((255 * 0.5).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '点击查看详细运势',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    user_data.UserDataLoaded state,
  ) {
    final deviceCount = state.connectedDevices.length;
    final messageCount = state.recentMessages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷操作',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.message,
                label: '发送消息',
                onTap: () {
                  context.push('/messages');
                },
                badgeCount: messageCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.devices,
                label: '设备管理',
                onTap: () {
                  context.push('/device-scan');
                },
                badgeCount: deviceCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.bluetooth,
                label: '设备测试',
                onTap: () {
                  context.push('/device-test');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.person,
                label: '个人资料',
                onTap: () {
                  context.push('/profile');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.settings,
                label: '设置',
                onTap: () {
                  // TODO: 跳转到设置页面
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: SizedBox(), // 占位符
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentMessages(
    BuildContext context,
    user_data.UserDataLoaded state,
  ) {
    final recentMessages = state.recentMessages.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近消息',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                context.push('/messages');
              },
              child: Text('查看全部 (${state.recentMessages.length})'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentMessages.isEmpty)
          _buildEmptyMessages(context)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: recentMessages.map((message) {
                  return Column(
                    children: [
                      _RealMessageItem(
                        message: message,
                        onTap: () {
                          context.push('/message-detail', extra: message);
                        },
                      ),
                      if (message != recentMessages.last)
                        const Divider(height: 32),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMessages(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMessageItem(
              context,
              Icons.send,
              '发送的消息',
              '暂无发送的消息',
              '刚刚',
              () => context.push('/messages'),
            ),
            const Divider(height: 32),
            _buildMessageItem(
              context,
              Icons.inbox,
              '接收的消息',
              '暂无接收的消息',
              '刚刚',
              () => context.push('/messages'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String time,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDevice(
    BuildContext context,
    user_data.UserDataLoaded state,
  ) {
    final connectedDevices = state.connectedDevices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已连接设备',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (connectedDevices.isEmpty)
          _buildEmptyDevice(context)
        else
          Column(
            children: connectedDevices.map((device) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RealDeviceItem(
                  device: device,
                  onTap: () {
                    context.push(
                      '/device-control',
                      extra: {'deviceId': device.id, 'deviceName': device.name},
                    );
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyDevice(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          context.push('/device-scan');
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bluetooth_connected,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '暂无连接设备',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击扫描设备',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 快捷操作按钮组件
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withAlpha((255 * 0.2).round()),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 真实消息项组件
class _RealMessageItem extends StatelessWidget {
  final user_data.MessageInfo message;
  final VoidCallback onTap;

  const _RealMessageItem({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                message.sender != null ? Icons.inbox : Icons.send,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.sender ?? message.recipient ?? '未知',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _formatTimestamp(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

// 真实设备项组件
class _RealDeviceItem extends StatelessWidget {
  final user_data.DeviceInfo device;
  final VoidCallback onTap;

  const _RealDeviceItem({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: device.isConnected
                      ? AppColors.success.withAlpha((255 * 0.1).round())
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  device.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: device.isConnected
                      ? AppColors.success
                      : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          device.isConnected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: device.isConnected
                              ? AppColors.success
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isConnected ? '已连接' : '未连接',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: device.isConnected
                                    ? AppColors.success
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (device.batteryLevel != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.battery_std,
                            size: 16,
                            color: _getBatteryColor(device.batteryLevel!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device.batteryLevel}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _getBatteryColor(device.batteryLevel!),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel >= 50) return AppColors.success;
    if (batteryLevel >= 20) return AppColors.warning;
    return AppColors.error;
  }
}
