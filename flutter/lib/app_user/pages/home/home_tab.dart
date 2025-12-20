import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/status_dashboard.dart';
import '../../widgets/device_info_card.dart';
import '../../state/device_control_state.dart';
import '../../../core/ble/ble_protocol.dart';

/// 首页 (A) - 现代蓝牙寻呼机Dashboard主页
/// 包含状态栏Dashboard、设备信息卡片、快速操作区域
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 移除AppBar，使用现代的状态栏Dashboard
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 应用标题和设置按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'BiPuPu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _openSettings(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => _openNotifications(context),
                    ),
                  ],
                ),
              ),
            ),

            // 状态栏Dashboard
            const SliverToBoxAdapter(child: StatusDashboard()),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 设备信息卡片
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: DeviceInfoCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 快速操作区域标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '快速操作',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showAllActions(context),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 快速操作网格
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildListDelegate([
                  _QuickActionCard(
                    icon: Icons.message,
                    title: '发送消息',
                    subtitle: '向设备发送通知',
                    color: Colors.blue,
                    onTap: () => _sendMessage(context),
                  ),
                  _QuickActionCard(
                    icon: Icons.vibration,
                    title: '震动测试',
                    subtitle: '测试设备震动',
                    color: Colors.orange,
                    onTap: () => _testVibration(context),
                  ),
                  _QuickActionCard(
                    icon: Icons.lightbulb,
                    title: 'LED测试',
                    subtitle: '测试设备LED',
                    color: Colors.yellow,
                    onTap: () => _testLed(context),
                  ),
                  _QuickActionCard(
                    icon: Icons.emergency,
                    title: '紧急呼叫',
                    subtitle: '发送紧急通知',
                    color: Colors.red,
                    onTap: () => _sendEmergency(context),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 最近消息标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '最近消息',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _viewAllMessages(context),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 最近消息列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _MessageItem(
                    title: '测试消息 ${index + 1}',
                    content: '这是一条测试消息内容，用于演示消息列表功能。',
                    time: '${index + 1}分钟前',
                    isRead: index % 2 == 0,
                    onTap: () => _viewMessage(context, index),
                  );
                }, childCount: 5),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('设置功能开发中')));
  }

  void _openNotifications(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('通知功能开发中')));
  }

  void _showAllActions(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('全部操作功能开发中')));
  }

  void _sendMessage(BuildContext context) {
    final cubit = context.read<DeviceControlCubit>();
    if (cubit.isConnected) {
      cubit.sendSimpleNotification(text: '快速测试消息');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('测试消息已发送')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先连接设备')));
    }
  }

  void _testVibration(BuildContext context) {
    final cubit = context.read<DeviceControlCubit>();
    if (cubit.isConnected) {
      cubit.sendSimpleNotification(
        text: '震动测试',
        vibration: VibrationPattern.medium,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('震动测试已发送')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先连接设备')));
    }
  }

  void _testLed(BuildContext context) {
    final cubit = context.read<DeviceControlCubit>();
    if (cubit.isConnected) {
      cubit.sendRgbSequence(
        colors: [RgbColor.colorRed, RgbColor.colorGreen, RgbColor.colorBlue],
        text: 'LED测试',
        duration: 2000,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('LED测试已发送')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先连接设备')));
    }
  }

  void _sendEmergency(BuildContext context) {
    final cubit = context.read<DeviceControlCubit>();
    if (cubit.isConnected) {
      cubit.sendUrgentNotification('紧急呼叫测试');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('紧急呼叫已发送')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先连接设备')));
    }
  }

  void _viewAllMessages(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('消息列表功能开发中')));
  }

  void _viewMessage(BuildContext context, int index) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('查看消息 ${index + 1}')));
  }
}

/// 快速操作卡片
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 消息项
class _MessageItem extends StatelessWidget {
  final String title;
  final String content;
  final String time;
  final bool isRead;
  final VoidCallback onTap;

  const _MessageItem({
    required this.title,
    required this.content,
    required this.time,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              // 未读指示器
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
