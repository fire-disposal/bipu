import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/components/ui_components.dart';
import '../../controllers/home_controller.dart';
import '../../models/poster_model.dart';
import 'bluetooth_scan_page.dart';
import 'voice_test_page.dart';

/// 极简首页
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return UIPageContainer(
      child: Column(
        children: [
          // 顶部：BIPUPU标题
          _buildTitleSection(context),

          const SizedBox(height: 24),

          // 中部：海报轮播
          _buildPosterCarousel(context, controller),

          const SizedBox(height: 32),

          // 底部：功能单元格
          _buildFunctionGrid(context),
        ],
      ),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          // 主标题
          Text(
            'BIPUPU',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              letterSpacing: 2.0,
            ),
          ),

          // 副标题
          Text(
            '宇宙传讯',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.mutedForeground,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建海报轮播
  Widget _buildPosterCarousel(BuildContext context, HomeController controller) {
    return Obx(() {
      if (controller.posters.isEmpty) {
        return _buildEmptyCarousel(context);
      }

      return Column(
        children: [
          // 轮播容器
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: controller.posters.length,
              onPageChanged: (index) {
                controller.updatePageIndex(index);
              },
              itemBuilder: (context, index) {
                final poster = controller.posters[index];
                return _buildPosterItem(context, poster);
              },
            ),
          ),

          const SizedBox(height: 12),

          // 指示点
          _buildPageIndicator(controller),
        ],
      );
    });
  }

  /// 构建空轮播状态
  Widget _buildEmptyCarousel(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ShadTheme.of(context).colorScheme.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              '暂无海报',
              style: TextStyle(
                color: ShadTheme.of(context).colorScheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建海报项
  Widget _buildPosterItem(BuildContext context, PosterResponse poster) {
    final theme = ShadTheme.of(context);
    final controller = HomeController.to;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: controller.getPosterImageUrl(poster.id),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.muted,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.muted,
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: theme.colorScheme.mutedForeground,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建页面指示器
  Widget _buildPageIndicator(HomeController controller) {
    return Obx(() {
      final theme = ShadTheme.of(Get.context!);

      if (controller.posters.length <= 1) {
        return const SizedBox.shrink();
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          controller.posters.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == controller.selectedPosterIndex.value
                  ? theme.colorScheme.primary
                  : ShadTheme.of(
                      Get.context!,
                    ).colorScheme.mutedForeground.withOpacity(0.3),
            ),
          ),
        ),
      );
    });
  }

  /// 构建功能网格
  Widget _buildFunctionGrid(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '功能',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
          ),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildFunctionCell(
                context,
                icon: Icons.bluetooth,
                label: '蓝牙扫描',
                onTap: () => Get.to(() => const BluetoothScanPage()),
              ),
              _buildFunctionCell(
                context,
                icon: Icons.mic,
                label: '语音测试',
                onTap: () => Get.to(() => const VoiceTestPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建功能单元格
  Widget _buildFunctionCell(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
