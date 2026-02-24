import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../shared/models/poster_model.dart';
import '../../logic/poster_provider.dart';

/// 海报轮播组件
class PosterCarousel extends HookConsumerWidget {
  /// 轮播高度
  final double height;

  /// 是否显示指示器
  final bool showIndicator;

  /// 是否自动播放
  final bool autoPlay;

  /// 自动播放间隔（毫秒）
  final int autoPlayInterval;

  /// 点击海报回调
  final Function(PosterResponse poster)? onPosterTap;

  const PosterCarousel({
    super.key,
    this.height = 180,
    this.showIndicator = true,
    this.autoPlay = true,
    this.autoPlayInterval = 5000,
    this.onPosterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosters = ref.watch(activePostersProvider);
    final currentPage = useState(0);
    final pageController = usePageController();
    final autoPlayTimer = useRef<Timer?>(null);

    // 自动播放逻辑
    useEffect(() {
      if (autoPlay) {
        autoPlayTimer.value?.cancel();
        autoPlayTimer.value = Timer.periodic(
          Duration(milliseconds: autoPlayInterval),
          (timer) {
            if (pageController.hasClients) {
              final postersLength = asyncPosters.value?.length ?? 1;
              final nextPage =
                  (currentPage.value + 1) %
                  (postersLength == 0 ? 1 : postersLength);
              pageController.animateToPage(
                nextPage.toInt(),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
        );
      }

      return () {
        autoPlayTimer.value?.cancel();
        autoPlayTimer.value = null;
      };
    }, [autoPlay, autoPlayInterval, asyncPosters.value?.length]);

    return SizedBox(
      height: height,
      child: asyncPosters.when(
        data: (posters) {
          if (posters.isEmpty) {
            return _buildPlaceholder(context);
          }

          return Column(
            children: [
              // 轮播区域
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) => currentPage.value = index,
                  itemCount: posters.length,
                  itemBuilder: (context, index) {
                    final poster = posters[index];
                    return _buildPosterItem(context, poster);
                  },
                ),
              ),

              // 指示器
              if (showIndicator && posters.length > 1) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildIndicator(context, posters.length, currentPage.value),
              ],
            ],
          );
        },
        loading: () => _buildLoading(context),
        error: (error, stack) => _buildError(context, error, ref),
      ),
    );
  }

  /// 构建海报项
  Widget _buildPosterItem(BuildContext context, PosterResponse poster) {
    return GestureDetector(
      onTap: () {
        if (onPosterTap != null) {
          onPosterTap!(poster);
        } else if (poster.linkUrl != null && poster.linkUrl!.isNotEmpty) {
          // 默认处理：如果有链接，尝试打开
          _handlePosterLink(context, poster.linkUrl!);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            children: [
              // 海报图片
              _buildPosterImage(context, poster),

              // 标题遮罩
              if (poster.title.isNotEmpty) _buildTitleOverlay(context, poster),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建海报图片
  Widget _buildPosterImage(BuildContext context, PosterResponse poster) {
    return Image.network(
      poster.fullImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '加载失败',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建标题遮罩
  Widget _buildTitleOverlay(BuildContext context, PosterResponse poster) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Text(
          poster.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 构建指示器
  Widget _buildIndicator(BuildContext context, int count, int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无海报',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoading(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// 构建错误状态
  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '加载失败',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  // 重新加载海报数据
                  ref.invalidate(activePostersProvider);
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理海报链接
  void _handlePosterLink(BuildContext context, String linkUrl) {
    // TODO: 实现链接处理逻辑
    // 可以打开网页、跳转到应用内页面等
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击海报: $linkUrl'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
