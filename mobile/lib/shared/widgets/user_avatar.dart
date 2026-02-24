import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/services/avatar_service.dart';

/// 用户头像组件
///
/// 显示用户头像，支持：
/// - 从后端 API 加载头像图片
/// - 本地缓存
/// - 无头像时显示首字母占位符
/// - 自定义尺寸和样式
///
/// 使用示例：
/// ```dart
/// UserAvatar(
///   bipupuId: 'user123',
///   radius: 24,
///   onTap: () => print('头像被点击'),
/// )
/// ```
class UserAvatar extends HookConsumerWidget {
  /// 用户的 bipupu_id（必需）
  final String bipupuId;

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

  const UserAvatar({
    super.key,
    required this.bipupuId,
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
        placeholderColor ?? theme.colorScheme.primaryContainer;
    final effectiveTextColor =
        textColor ?? theme.colorScheme.onPrimaryContainer;

    // 获取首字母
    final initial = bipupuId.isNotEmpty ? bipupuId[0].toUpperCase() : '?';

    // 加载头像
    useEffect(() {
      bool mounted = true;

      Future<void> loadAvatar() async {
        isLoading.value = true;
        hasError.value = false;

        try {
          // 先尝试从缓存获取
          final cache = ref.read(avatarCacheProvider);
          final cachedData = cache['user:$bipupuId'];
          if (cachedData != null && mounted) {
            avatarData.value = cachedData;
            isLoading.value = false;
            return;
          }

          // 从 API 获取
          final avatarService = ref.read(avatarApiProvider);
          final data = await avatarService.getUserAvatarData(bipupuId);

          if (mounted) {
            if (data != null) {
              avatarData.value = data;
              // 缓存头像
              ref
                  .read(avatarCacheProvider.notifier)
                  .cacheUserAvatar(bipupuId, data);
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
    }, [bipupuId]);

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
            color: borderColor ?? theme.colorScheme.primary,
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

/// 带状态的用户头像组件（用于需要刷新头像的场景）
class UserAvatarWithRefresh extends HookConsumerWidget {
  final String bipupuId;
  final double radius;
  final bool showLoadingIndicator;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatarWithRefresh({
    super.key,
    required this.bipupuId,
    this.radius = 20,
    this.showLoadingIndicator = false,
    this.onTap,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(0);

    // 提供刷新回调
    final userAvatar = UserAvatar(
      key: ValueKey('avatar-$bipupuId-${refreshKey.value}'),
      bipupuId: bipupuId,
      radius: radius,
      showLoadingIndicator: showLoadingIndicator,
      onTap: onTap,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );

    return userAvatar;
  }
}

/// 头像列表组件
///
/// 显示多个用户头像的堆叠
class UserAvatarStack extends StatelessWidget {
  /// 用户 bipupu_id 列表
  final List<String> bipupuIds;

  /// 头像半径
  final double radius;

  /// 头像之间的重叠量
  final double overlap;

  /// 最大显示数量（超过则显示 +N）
  final int maxVisible;

  const UserAvatarStack({
    super.key,
    required this.bipupuIds,
    this.radius = 16,
    this.overlap = 8,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    final visibleIds = bipupuIds.take(maxVisible).toList();
    final remainingCount = bipupuIds.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleIds.map((bipupuId) {
          final index = visibleIds.indexOf(bipupuId);
          return Transform.translate(
            offset: Offset(-index * overlap, 0),
            child: UserAvatar(
              bipupuId: bipupuId,
              radius: radius,
              borderWidth: 1,
              borderColor: Theme.of(context).colorScheme.surface,
            ),
          );
        }),
        if (remainingCount > 0) ...[
          Transform.translate(
            offset: Offset(-visibleIds.length * overlap, 0),
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
