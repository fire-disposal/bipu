import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bipupu/api/core/api_client.dart';

/// 简化版服务号头像组件
///
/// 只负责：
/// 1. 显示服务号头像图片
/// 2. 无头像时显示通知图标
/// 3. 支持点击交互
class ServiceAccountAvatar extends StatelessWidget {
  /// 头像URL（可选）
  final String? avatarUrl;

  /// 显示名称（用于调试）
  final String? displayName;

  /// 头像半径
  final double radius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否显示订阅状态指示器
  final bool showSubscriptionIndicator;

  /// 订阅状态（true表示已订阅）
  final bool isSubscribed;

  /// 自定义背景颜色
  final Color? backgroundColor;

  /// 自定义图标颜色
  final Color? iconColor;

  const ServiceAccountAvatar({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.radius = 50,
    this.onTap,
    this.showSubscriptionIndicator = false,
    this.isSubscribed = false,
    this.backgroundColor,
    this.iconColor,
  });

  /// 获取图片提供器
  ImageProvider? _getImageProvider(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    } else {
      // 相对路径，拼接基础URL
      final baseUrl = ApiClient().baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
      return CachedNetworkImageProvider('$baseUrl$url');
    }
  }

  /// 构建回退图标
  Widget _buildFallbackIcon() {
    return Icon(
      isSubscribed ? Icons.notifications_active : Icons.notifications_none,
      size: radius * 0.8,
      color: iconColor ?? Colors.white,
    );
  }

  /// 构建订阅状态指示器
  Widget? _buildSubscriptionIndicator() {
    if (!showSubscriptionIndicator) return null;

    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSubscribed ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          isSubscribed ? Icons.check : Icons.add,
          size: radius * 0.2,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 确定背景颜色
    final bgColor =
        backgroundColor ??
        (isSubscribed
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: avatarUrl != null ? _getImageProvider(avatarUrl!) : null,
      child: avatarUrl == null ? _buildFallbackIcon() : null,
    );

    // 添加订阅状态指示器
    final subscriptionIndicator = _buildSubscriptionIndicator();
    if (subscriptionIndicator != null) {
      avatar = Stack(children: [avatar, subscriptionIndicator]);
    }

    // 添加点击交互
    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

/// 服务号头像列表项
///
/// 用于在列表中显示服务号头像，带有标题和描述
class ServiceAccountAvatarListItem extends StatelessWidget {
  final String serviceName;
  final String? displayName;
  final String? description;
  final String? avatarUrl;
  final bool isSubscribed;
  final VoidCallback? onTap;
  final VoidCallback? onSubscribeTap;
  final double avatarRadius;

  const ServiceAccountAvatarListItem({
    super.key,
    required this.serviceName,
    this.displayName,
    this.description,
    this.avatarUrl,
    this.isSubscribed = false,
    this.onTap,
    this.onSubscribeTap,
    this.avatarRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ServiceAccountAvatar(
        avatarUrl: avatarUrl,
        displayName: displayName,
        radius: avatarRadius,
        showSubscriptionIndicator: true,
        isSubscribed: isSubscribed,
        onTap: onTap,
      ),
      title: Text(
        displayName ?? serviceName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: description != null
          ? Text(
              description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          : null,
      trailing: onSubscribeTap != null
          ? IconButton(
              icon: Icon(
                isSubscribed
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: isSubscribed
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              onPressed: onSubscribeTap,
            )
          : null,
      onTap: onTap,
    );
  }
}
