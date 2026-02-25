import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/services/avatar_service.dart';
import '../../features/auth/logic/auth_notifier.dart';
import '../../core/config/app_config.dart';

/// 简化的用户头像组件
///
/// 显示用户头像，支持：
/// - 从后端API加载头像
/// - 缓存头像URL
/// - 无头像时显示首字母占位符
/// - 默认头像
class UserAvatar extends ConsumerWidget {
  /// 用户的bipupu_id
  final String bipupuId;

  /// 头像半径
  final double radius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 边框颜色
  final Color? borderColor;

  /// 边框宽度
  final double borderWidth;

  /// 自定义头像URL（可选，如果不提供则使用默认或API获取）
  final String? avatarUrl;

  /// 头像版本号，用于缓存失效
  final int avatarVersion;

  /// 是否显示加载指示器
  final bool showLoadingIndicator;

  const UserAvatar({
    super.key,
    required this.bipupuId,
    this.radius = 20,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.avatarUrl,
    this.avatarVersion = 0,
    this.showLoadingIndicator = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 使用新的userAvatarUrlProvider安全地获取头像URL
    final finalAvatarUrl = ref.watch(
      userAvatarUrlProvider(
        UserAvatarUrlParams(
          bipupuId: bipupuId,
          cacheKey: 'user:$bipupuId',
          customUrl: avatarUrl,
          avatarVersion: avatarVersion,
        ),
      ),
    );

    // 获取首字母
    final initial = bipupuId.isNotEmpty ? bipupuId[0].toUpperCase() : '?';

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
              color: theme.colorScheme.primary,
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
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // 图片加载失败，显示占位符
            return _buildPlaceholder(
              context,
              initial,
              theme.colorScheme.primaryContainer,
              theme.colorScheme.onPrimaryContainer,
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

/// 当前用户头像组件
///
/// 自动获取当前登录用户的头像
class CurrentUserAvatar extends ConsumerWidget {
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final bool showLoadingIndicator;

  const CurrentUserAvatar({
    super.key,
    this.radius = 20,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.showLoadingIndicator = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState.user;

    if (user == null) {
      // 用户未登录，显示默认头像
      return _buildDefaultAvatar(context);
    }

    return UserAvatar(
      bipupuId: user.bipupuId,
      radius: radius,
      onTap: onTap,
      borderColor: borderColor,
      borderWidth: borderWidth,
      avatarUrl: user.avatarUrl,
      avatarVersion: user.avatarVersion,
      showLoadingIndicator: showLoadingIndicator,
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? theme.colorScheme.outline,
                width: borderWidth,
              )
            : null,
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: radius,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 头像上传器组件
///
/// 显示用户头像并支持上传新头像
class AvatarUploader extends ConsumerWidget {
  final String bipupuId;
  final double radius;
  final bool showEditButton;
  final VoidCallback? onUploadComplete;
  final String? currentAvatarUrl;

  const AvatarUploader({
    super.key,
    required this.bipupuId,
    this.radius = 32,
    this.showEditButton = false,
    this.onUploadComplete,
    this.currentAvatarUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 头像
        UserAvatar(
          bipupuId: bipupuId,
          radius: radius,
          avatarUrl: currentAvatarUrl,
        ),

        // 编辑按钮
        if (showEditButton)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                _showAvatarUploadDialog(context, ref);
              },
              child: Container(
                width: radius * 0.6,
                height: radius * 0.6,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: radius * 0.35,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAvatarUploadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('更换头像'),
          content: const Text('请选择新的头像图片'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 实现头像上传逻辑
                debugPrint('头像上传功能待实现');
              },
              child: const Text('选择图片'),
            ),
          ],
        );
      },
    );
  }
}
