import 'package:flutter/material.dart';

/// SnackBar 类型枚举
enum SnackBarType {
  success,
  error,
  info,
  warning,
  message, // 新消息提示
}

/// 统一的 Toast/SnackBar 服务
class ToastService {
  static final ToastService _instance = ToastService._internal();

  factory ToastService() {
    return _instance;
  }

  ToastService._internal();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 显示成功提示
  void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(message, type: SnackBarType.success, duration: duration);
  }

  /// 显示错误提示
  void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(message, type: SnackBarType.error, duration: duration);
  }

  /// 显示信息提示
  void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(message, type: SnackBarType.info, duration: duration);
  }

  /// 显示警告提示
  void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(message, type: SnackBarType.warning, duration: duration);
  }

  /// 显示新消息提示（用于 IM 服务）
  void showMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _showSnackBar(
      message,
      type: SnackBarType.message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// 内部方法：显示 SnackBar
  void _showSnackBar(
    String message, {
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) {
      debugPrint(
        "ToastService: ScaffoldMessengerState is null. Message: $message",
      );
      return;
    }

    state.removeCurrentSnackBar();
    state.showSnackBar(
      _buildSnackBar(message, type: type, duration: duration, onTap: onTap),
    );
  }

  /// 构建 SnackBar Widget
  SnackBar _buildSnackBar(
    String message, {
    required SnackBarType type,
    required Duration duration,
    VoidCallback? onTap,
  }) {
    final (backgroundColor, icon) = _getStyleForType(type);

    return SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      onVisible: onTap,
    );
  }

  /// 获取 SnackBar 类型对应的样式
  (Color, IconData?) _getStyleForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return (Colors.green, Icons.check_circle_outline);
      case SnackBarType.error:
        return (Colors.red, Icons.error_outline);
      case SnackBarType.info:
        return (Colors.blue, Icons.info_outline);
      case SnackBarType.warning:
        return (Colors.orange, Icons.warning_amber_rounded);
      case SnackBarType.message:
        return (const Color(0xFF2196F3), Icons.mail_outline);
    }
  }

  /// 清除当前 SnackBar
  void dismiss() {
    scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
  }
}
