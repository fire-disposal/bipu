import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/services/avatar_service.dart';
import '../../core/config/app_config.dart';

/// 简化的服务号头像组件
///
/// 显示服务号头像，支持：
/// - 从后端API加载头像
/// - 缓存头像URL
/// - 无头像时显示服务号首字母占位符
/// - 默认头像
class ServiceAccountAvatar extends ConsumerWidget {
  /// 服务号名称
  final String serviceName;

  /// 头像半径
  final double radius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 边框颜色
  final Color? borderColor;

  /// 边框宽度
  final double borderWidth;

  /// 自定义头像URL（可选）
  final String? avatarUrl;

  /// 是否显示加载指示器
  final bool showLoadingIndicator;

  const ServiceAccountAvatar({
    super.key,
    required this.serviceName,
    this.radius = 20,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.avatarUrl,
    this.showLoadingIndicator = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 使用新的serviceAvatarUrlProvider安全地获取头像URL
    final finalAvatarUrl = ref.watch(
      serviceAvatarUrlProvider(
        ServiceAvatarUrlParams(
          serviceName: serviceName,
          cacheKey: 'service:$serviceName',
          customUrl: avatarUrl,
        ),
      ),
    );

    // 获取服务号名称的首字母（去除点号）
    final cleanName = serviceName.replaceAll('.', '');
    final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '?';

    // 构建头像内容
    Widget avatarContent;

    if (showLoadingIndicator) {
      // 加载中
      avatarContent = SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Center(
          child: SizedBox(
            width: radius * 0.6,
            height: radius * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      );
    } else {
      // 使用头像图片
      avatarContent = ClipOval(
        child: Image.network(
          finalAvatarUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            // 显示加载指示器
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: theme.colorScheme.secondary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // 图片加载失败，显示占位符
            return _buildPlaceholder(
              context,
              initial,
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.onSecondaryContainer,
            );
          },
        ),
      );
    }

    // 添加边框（如果有）
    if (borderWidth > 0) {
      avatarContent = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? theme.colorScheme.secondary,
            width: borderWidth,
          ),
        ),
        child: avatarContent,
      );
    }

    // 添加点击交互
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarContent);
    }

    return avatarContent;
  }

  /// 构建占位符
  Widget _buildPlaceholder(
    BuildContext context,
    String initial,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: textColor,
            fontSize: radius,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 服务号头像网格组件
class ServiceAccountAvatarGrid extends StatelessWidget {
  /// 服务号名称列表
  final List<String> serviceNames;

  /// 头像半径
  final double radius;

  /// 每行显示的数量
  final int crossAxisCount;

  /// 头像之间的间距
  final double spacing;

  const ServiceAccountAvatarGrid({
    super.key,
    required this.serviceNames,
    this.radius = 24,
    this.crossAxisCount = 4,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: serviceNames.length,
      itemBuilder: (context, index) {
        final serviceName = serviceNames[index];
        return Center(
          child: ServiceAccountAvatar(serviceName: serviceName, radius: radius),
        );
      },
    );
  }
}

/// 服务号头像与名称组合组件
class ServiceAccountAvatarTile extends StatelessWidget {
  /// 服务号名称
  final String serviceName;

  /// 服务号描述（可选）
  final String? description;

  /// 头像半径
  final double radius;

  /// 点击回调
  final VoidCallback? onTap;

  const ServiceAccountAvatarTile({
    super.key,
    required this.serviceName,
    this.description,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ServiceAccountAvatar(serviceName: serviceName, radius: radius),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
