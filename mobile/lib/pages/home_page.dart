import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../controllers/home_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/auth_controller.dart';

/// 极简首页 - GetX风格
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = HomeController.to;
    final appController = AppController.to;
    final authController = AuthController.to;

    // 刷新函数
    Future<void> handleRefresh() async {
      await homeController.refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bipupu - 宇宙传讯'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Get.snackbar('通知', '通知功能开发中');
            },
          ),
          IconButton(
            icon: Obx(
              () => Icon(
                appController.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
            ),
            onPressed: () {
              appController.toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        child: CustomScrollView(
          slivers: [
            // 用户欢迎卡片
            SliverToBoxAdapter(
              child: Obx(() {
                final user = authController.user.value;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Get.theme.colorScheme.primary,
                            child: Text(
                              user?.username.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.username ?? '游客',
                                  style: Get.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.bipupuId ?? '未登录',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color:
                                        Get.theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () {
                              authController.logout();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            // 海报轮播
            SliverToBoxAdapter(
              child: Obx(() {
                final posters = homeController.posters;
                if (posters.isEmpty && !homeController.isLoading.value) {
                  return const SizedBox();
                }

                return SizedBox(
                  height: 180,
                  child: PageView.builder(
                    itemCount: posters.length,
                    itemBuilder: (context, index) {
                      final poster = posters[index];
                      return GestureDetector(
                        onTap: () {
                          if (poster.linkUrl?.isNotEmpty == true) {
                            Get.snackbar('海报', '点击了: ${poster.title}');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                // 海报图片占位
                                Container(
                                  color: Get.theme.colorScheme.primaryContainer,
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Get
                                          .theme
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                // 标题
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      poster.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 快速功能入口
            SliverToBoxAdapter(child: _buildQuickActions()),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 加载状态
            SliverToBoxAdapter(
              child: Obx(() {
                if (homeController.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox();
              }),
            ),

            // 错误提示
            SliverToBoxAdapter(
              child: Obx(() {
                final error = homeController.error.value;
                if (error.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Get.theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Get.theme.colorScheme.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              homeController.refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              }),
            ),

            // 底部间距
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.call,
        'label': '传唤',
        'color': Colors.blue,
        'route': '/pager',
      },
      {
        'icon': Icons.message,
        'label': '消息',
        'color': Colors.green,
        'route': '/messages',
      },
      {
        'icon': Icons.people,
        'label': '联系人',
        'color': Colors.orange,
        'route': '/contacts',
      },
      {
        'icon': Icons.person,
        'label': '个人资料',
        'color': Colors.purple,
        'route': '/profile',
      },
      {
        'icon': Icons.settings,
        'label': '设置',
        'color': Colors.grey,
        'route': '/settings',
      },
      {
        'icon': Icons.bluetooth,
        'label': '蓝牙',
        'color': Colors.indigo,
        'route': '/bluetooth',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () {
              final route = action['route'] as String;
              if (route == '/bluetooth') {
                Get.snackbar('提示', '蓝牙功能保持原有实现');
              } else {
                Get.toNamed(route);
              }
            },
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (action['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: Get.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
