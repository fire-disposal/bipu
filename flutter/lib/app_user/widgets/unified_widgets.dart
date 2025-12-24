/// 统一组件库
/// 提供跨应用的一致UI组件
library;

import 'package:flutter/material.dart';

/// 加载指示器
class UnifiedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const UnifiedLoadingIndicator({
    super.key,
    this.message,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? theme.colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 错误显示组件
class UnifiedErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const UnifiedErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '出错了',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? '重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状态组件
class UnifiedEmptyWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const UnifiedEmptyWidget({
    super.key,
    required this.message,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 成功提示组件
class UnifiedSuccessWidget extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Duration? autoDismissDuration;

  const UnifiedSuccessWidget({
    super.key,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.autoDismissDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 自动关闭逻辑
    if (autoDismissDuration != null) {
      Future.delayed(autoDismissDuration!, () {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              '成功',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.arrow_forward),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 确认对话框
class UnifiedConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const UnifiedConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? '取消'),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmText ?? '确认'),
        ),
      ],
    );
  }

  /// 显示确认对话框
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => UnifiedConfirmDialog(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            isDestructive: isDestructive,
          ),
        ) ??
        false;
  }
}
