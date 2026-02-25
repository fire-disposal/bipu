import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 统一的UI组件库 - 封装shadcn_ui组件，避免命名冲突

// ============================================
// 按钮组件
// ============================================

/// 主按钮
class UIButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const UIButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShadTheme.of(context).colorScheme.primaryForeground,
              ),
            )
          : child,
    );
  }
}

/// 次要按钮
class UISecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const UISecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.secondary(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShadTheme.of(context).colorScheme.secondaryForeground,
              ),
            )
          : child,
    );
  }
}

/// 轮廓按钮
class UIOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const UIOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.outline(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShadTheme.of(context).colorScheme.foreground,
              ),
            )
          : child,
    );
  }
}

/// 危险按钮
class UIDestructiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const UIDestructiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.destructive(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShadTheme.of(context).colorScheme.destructiveForeground,
              ),
            )
          : child,
    );
  }
}

/// 幽灵按钮
class UIGhostButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const UIGhostButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.ghost(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShadTheme.of(context).colorScheme.foreground,
              ),
            )
          : child,
    );
  }
}

// ============================================
// 卡片组件
// ============================================

/// 基础卡片
class UICard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const UICard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

/// 带标题的卡片
class UICardWithTitle extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? titlePadding;

  const UICardWithTitle({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.titlePadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return UICard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: titlePadding ?? const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ============================================
// 输入框组件
// ============================================

/// 文本输入框
class UIInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final bool autoFocus;

  const UIInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.foreground,
              ),
            ),
          ),
        ShadInput(
          controller: controller,
          placeholder: hintText != null ? Text(hintText!) : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          autofocus: autoFocus,
          leading: prefixIcon,
          trailing: suffixIcon,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
      ],
    );
  }
}

/// 密码输入框
class UIPasswordInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const UIPasswordInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<UIPasswordInput> createState() => _UIPasswordInputState();
}

class _UIPasswordInputState extends State<UIPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return UIInput(
      controller: widget.controller,
      hintText: widget.hintText ?? '请输入密码',
      labelText: widget.labelText,
      errorText: widget.errorText,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      onChanged: widget.onChanged,
      validator: widget.validator,
      enabled: widget.enabled,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

// ============================================
// 布局组件
// ============================================

/// 页面容器
class UIPageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeArea;

  const UIPageContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

/// 分隔线
class UIDivider extends StatelessWidget {
  final double height;
  final Color? color;
  final EdgeInsetsGeometry margin;

  const UIDivider({
    super.key,
    this.height = 1.0,
    this.color,
    this.margin = const EdgeInsets.symmetric(vertical: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      margin: margin,
      height: height,
      color: color ?? theme.colorScheme.border,
    );
  }
}

/// 空状态
class UIEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const UIEmptyState({
    super.key,
    this.icon = Icons.inbox,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

// ============================================
// 工具函数
// ============================================

/// 显示Snackbar
void showUISnackbar(
  BuildContext context,
  String message, {
  String title = '提示',
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// 显示确认对话框
Future<bool?> showUIConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '确认',
  String cancelText = '取消',
}) async {
  final theme = ShadTheme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        backgroundColor: theme.colorScheme.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          UIOutlineButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          UIButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}

/// 显示加载对话框
void showUILoadingDialog(BuildContext context, {String message = '加载中...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = ShadTheme.of(context);

      return Dialog(
        backgroundColor: theme.colorScheme.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Text(
                message,
                style: TextStyle(color: theme.colorScheme.foreground),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 隐藏加载对话框
void hideUILoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
