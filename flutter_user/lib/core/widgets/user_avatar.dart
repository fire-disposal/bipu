import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bipupu/api/core/api_client.dart';

/// 简化版用户头像组件
///
/// 只负责：
/// 1. 显示头像图片
/// 2. 无头像时显示首字母
/// 3. 支持点击交互
class UserAvatar extends StatelessWidget {
  /// 头像URL（可选）
  final String? avatarUrl;

  /// 显示名称（用于首字母回退）
  final String? displayName;

  /// 头像半径
  final double radius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否显示编辑图标
  final bool showEditIcon;

  /// 自定义背景颜色
  final Color? backgroundColor;

  /// 自定义文本颜色
  final Color? textColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.radius = 50,
    this.onTap,
    this.showEditIcon = false,
    this.backgroundColor,
    this.textColor,
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

  /// 构建回退文本（首字母）
  Widget _buildFallbackText() {
    final initial = displayName?.isNotEmpty == true
        ? displayName![0].toUpperCase()
        : '?';

    return Text(
      initial,
      style: TextStyle(
        fontSize: radius * 0.64, // 32 when radius=50
        fontWeight: FontWeight.bold,
        color: textColor ?? Colors.white,
      ),
    );
  }

  /// 构建编辑图标
  Widget? _buildEditIcon() {
    if (!showEditIcon) return null;

    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(Icons.camera_alt, size: radius * 0.2, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 确定背景颜色
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: avatarUrl != null ? _getImageProvider(avatarUrl!) : null,
      child: avatarUrl == null ? _buildFallbackText() : null,
    );

    // 添加编辑图标
    final editIcon = _buildEditIcon();
    if (editIcon != null) {
      avatar = Stack(children: [avatar, editIcon]);
    }

    // 添加点击交互
    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

/// 用户头像小部件（简化版）
///
/// 用于需要简单头像显示的场景
class UserAvatarSmall extends StatelessWidget {
  final String? avatarUrl;
  final String? displayName;
  final double size;
  final VoidCallback? onTap;

  const UserAvatarSmall({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.size = 32,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      avatarUrl: avatarUrl,
      displayName: displayName,
      radius: size / 2,
      onTap: onTap,
    );
  }
}
