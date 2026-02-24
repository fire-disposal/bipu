import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/design_system.dart';
import '../../../core/bluetooth/ble_manager.dart';

import '../logic/home_provider.dart';
import 'widgets/poster_carousel.dart';
import 'widgets/bluetooth_status_card.dart';
import '../../bluetooth/ui/bluetooth_scan_screen.dart';
import '../../bluetooth/ui/device_control_screen.dart';
import '../../contacts/ui/contacts_screen.dart';
import '../../pager/ui/pager_screen.dart';
import '../../message/ui/message_list_screen.dart';
import '../../profile/ui/profile_screen.dart';

/// 首页广场
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFeeds = ref.watch(feedsProvider);
    Future<void> handleRefresh() async {
      // TODO: 实现刷新逻辑
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 通知
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        child: CustomScrollView(
          slivers: [
            // 蓝牙状态卡片
            SliverToBoxAdapter(
              child: BluetoothStatusCard(
                onConnectPressed: () {
                  // 导航到蓝牙扫描页面
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BluetoothScanScreen(),
                    ),
                  );
                },
                onControlPressed: () {
                  // 获取已连接的设备
                  final bleManager = ref.read(bleManagerProvider);
                  final connectedDevices = bleManager.connectedDevices;

                  if (connectedDevices.isNotEmpty) {
                    // 导航到设备控制页面
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DeviceControlScreen(
                          deviceId: connectedDevices.first.id,
                          deviceName: connectedDevices.first.name,
                        ),
                      ),
                    );
                  } else {
                    // 没有连接的设备，显示提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('请先连接蓝牙设备'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ),

            // 海报轮播区域
            SliverToBoxAdapter(
              child: PosterCarousel(
                height: 180,
                autoPlay: true,
                autoPlayInterval: 5000,
                onPosterTap: (poster) {
                  // 处理海报点击
                  if (poster.linkUrl?.isNotEmpty == true) {
                    // TODO: 处理链接跳转
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('点击海报: ${poster.title}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // 功能入口
            SliverToBoxAdapter(child: _buildQuickActions(context)),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // 广场动态
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('广场动态', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        // TODO: 查看更多
                      },
                      child: const Text('更多'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // 动态列表
            asyncFeeds.when(
              data: (feeds) {
                if (feeds.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyFeeds(context));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final feed = feeds[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 100 + index * 50),
                      child: _buildFeedCard(context, feed),
                    );
                  }, childCount: feeds.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) =>
                  SliverToBoxAdapter(child: Center(child: Text('加载失败：$error'))),
            ),

            // 底部间距
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  // 移除原有的轮播相关方法，使用新的PosterCarousel组件

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.call,
        'label': '传唤',
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PagerScreen()),
          );
        },
      },
      {
        'icon': Icons.message,
        'label': '消息',
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MessageListScreen()),
          );
        },
      },
      {
        'icon': Icons.person,
        'label': '联系人',
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        },
      },
      {
        'icon': Icons.settings,
        'label': '设置',
        'color': Colors.purple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return GestureDetector(
            onTap: action['onTap'] as VoidCallback,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  action['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFeeds(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无动态',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, FeedItem feed) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feed.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              feed.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (feed.imageUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  feed.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      height: 150,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${feed.createdAt.year}-${feed.createdAt.month}-${feed.createdAt.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
