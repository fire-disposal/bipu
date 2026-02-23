import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/theme/design_system.dart';
import '../../core/services/avatar_service.dart';

/// 服务号头像组件
///
/// 显示服务号头像，支持：
/// - 从后端 API 加载头像图片
/// - 本地缓存
/// - 无头像时显示服务号首字母占位符
/// - 自定义尺寸和样式
///
/// 使用示例：
/// ```dart
/// ServiceAccountAvatar(
///   serviceName: 'cosmic.fortune',
///   radius: 24,
///   onTap: () => print('头像被点击'),
/// )
/// ```
class ServiceAccountAvatar extends HookConsumerWidget {
  /// 服务号名称（必需）
  final String serviceName;

  /// 头像半径
  final double radius;

  /// 是否显示加载指示器
  final bool showLoadingIndicator;

  /// 点击回调
  final VoidCallback? onTap;

  /// 头像边框颜色
  final Color? borderColor;

  /// 头像边框宽度
  final double borderWidth;

  /// 占位符背景颜色（可选，默认使用主题色）
  final Color? placeholderColor;

  /// 文字颜色（可选，默认使用主题色）
  final Color? textColor;

  const ServiceAccountAvatar({
    super.key,
    required this.serviceName,
    this.radius = 20,
    this.showLoadingIndicator = false,
    this.onTap,
    this.borderColor,
    this.borderWidth = 2,
    this.placeholderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarData = useState<Uint8List?>(null);
    final isLoading = useState(false);
    final hasError = useState(false);

    // 计算占位符颜色
    final effectivePlaceholderColor =
        placeholderColor ?? theme.colorScheme.secondaryContainer;
    final effectiveTextColor =
        textColor ?? theme.colorScheme.onSecondaryContainer;

    // 获取服务号名称的首字母（去除点号）
    final cleanName = serviceName.replaceAll('.', '');
    final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '?';

    // 加载头像
    useEffect(() {
      bool mounted = true;

      Future<void> loadAvatar() async {
        isLoading.value = true;
        hasError.value = false;

        try {
          // 先尝试从缓存获取
          final cache = ref.read(avatarCacheProvider);
          final cachedData = cache['service:$serviceName'];
          if (cachedData != null && mounted) {
            avatarData.value = cachedData;
            isLoading.value = false;
            return;
          }

          // 从 API 获取
          final avatarService = ref.read(avatarApiProvider);
          final data = await avatarService.getServiceAccountAvatarData(
            serviceName,
          );

          if (mounted) {
            if (data != null) {
              avatarData.value = data;
              // 缓存头像
              ref
                  .read(avatarCacheProvider.notifier)
                  .cacheServiceAccountAvatar(serviceName, data);
            } else {
              hasError.value = true;
            }
            isLoading.value = false;
          }
        } catch (e) {
          if (mounted) {
            hasError.value = true;
            isLoading.value = false;
          }
        }
      }

      loadAvatar();

      return () {
        mounted = false;
      };
    }, [serviceName]);

    // 构建头像内容
    Widget avatarContent;

    if (isLoading.value && showLoadingIndicator) {
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
              color: effectiveTextColor,
            ),
          ),
        ),
      );
    } else if (avatarData.value != null) {
      // 有头像图片
      avatarContent = ClipOval(
        child: Image.memory(
          avatarData.value!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return _buildPlaceholder(
              context,
              initial,
              effectivePlaceholderColor,
              effectiveTextColor,
            );
          },
        ),
      );
    } else {
      // 无头像，显示占位符
      avatarContent = _buildPlaceholder(
        context,
        initial,
        effectivePlaceholderColor,
        effectiveTextColor,
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

/// 服务号头像列表（用于显示多个服务号）
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
    this.spacing = AppSpacing.md,
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ServiceAccountAvatar(serviceName: serviceName, radius: radius),
            const SizedBox(width: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.xs),
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
