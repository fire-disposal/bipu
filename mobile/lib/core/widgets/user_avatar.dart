import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../network/api_client.dart';

/// 统一头像组件
///
/// 支持两种解析模式（互斥，[bipupuId] 优先级更高）：
///
/// **模式 1 — bipupuId**
/// 根据 ID 的字符类型自动选择端点：
/// - 纯数字 → `/api/users/users/{id}/avatar`
/// - 含非数字字符（服务号） → `/api/service_accounts/{id}/avatar`
///
/// **模式 2 — avatarUrl**
/// 直接使用已知的头像 URL（相对路径自动拼接 baseUrl）。
///
/// 图片加载失败或 URL 为空时，降级显示 [displayName] 的首字母。
/// 若同时提供了 [fallbackIcon]，则优先显示图标（适用于个人中心页等场景）。
///
/// 示例：
/// ```dart
/// // 通过 ID 自动解析
/// UserAvatar(bipupuId: '000012', radius: 24)
/// UserAvatar(bipupuId: 'cosmic.news', displayName: 'Cosmic', radius: 20)
///
/// // 通过已有 URL
/// UserAvatar(avatarUrl: user.avatarUrl, displayName: user.nickname, radius: 36)
///
/// // 带图标降级
/// UserAvatar(
///   avatarUrl: user.avatarUrl,
///   radius: 36,
///   fallbackIcon: Icon(Icons.person, size: 36),
/// )
/// ```
class UserAvatar extends StatelessWidget {
  /// bipupuId — 自动选择端点（优先于 [avatarUrl]）
  final String? bipupuId;

  /// 已知头像 URL（相对或绝对路径均可）
  final String? avatarUrl;

  /// 加载失败时显示的名字（取第一个字符大写）
  final String? displayName;

  /// 加载失败时显示的图标（优先于 [displayName] 首字母）
  final Widget? fallbackIcon;

  final double radius;

  /// 圆形背景色，默认使用 surfaceContainerHighest
  final Color? backgroundColor;

  /// 首字母/图标的前景色，默认使用 onSurfaceVariant
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    this.bipupuId,
    this.avatarUrl,
    this.displayName,
    this.fallbackIcon,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(
         bipupuId != null || avatarUrl != null || displayName != null,
         'At least one of bipupuId, avatarUrl, or displayName must be provided',
       );

  /// 解析最终完整的头像 URL
  String? _resolveUrl() {
    final base = ApiClient.instance.dio.options.baseUrl;

    // 模式 1：通过 bipupuId 构建端点
    if (bipupuId != null && bipupuId!.isNotEmpty) {
      final isNumeric = RegExp(r'^\d+$').hasMatch(bipupuId!);
      final path = isNumeric
          ? '/api/users/users/$bipupuId/avatar'
          : '/api/service_accounts/$bipupuId/avatar';
      return '$base$path';
    }

    // 模式 2：使用已知 avatarUrl（可能是相对路径）
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return avatarUrl!.startsWith('http') ? avatarUrl : '$base$avatarUrl';
    }

    return null;
  }

  Widget _buildFallback(BuildContext context) {
    final bgColor =
        backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final fgColor =
        foregroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    if (fallbackIcon != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackIcon,
      );
    }

    // 取 bipupuId 或 displayName 的首字母作为占位
    final source = bipupuId?.isNotEmpty == true
        ? bipupuId!
        : (displayName?.isNotEmpty == true ? displayName! : '?');
    final letter = source.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        letter,
        style: TextStyle(fontWeight: FontWeight.bold, color: fgColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl();

    if (url == null) {
      return _buildFallback(context);
    }

    final bgColor =
        backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color:
                foregroundColor ??
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(context),
    );
  }
}
