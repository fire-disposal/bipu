/// 核心按钮组件
library;

import 'package:flutter/material.dart';

/// 按钮类型
enum CoreButtonType { primary, secondary, outline, text, danger }

/// 按钮大小
enum CoreButtonSize { small, medium, large }

/// 核心按钮组件
class CoreButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CoreButtonType type;
  final CoreButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Widget? child;

  const CoreButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CoreButtonType.primary,
    this.size = CoreButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.child,
  });

  factory CoreButton.primary({
    required String text,
    VoidCallback? onPressed,
    CoreButtonSize size = CoreButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return CoreButton(
      text: text,
      onPressed: onPressed,
      type: CoreButtonType.primary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  factory CoreButton.secondary({
    required String text,
    VoidCallback? onPressed,
    CoreButtonSize size = CoreButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return CoreButton(
      text: text,
      onPressed: onPressed,
      type: CoreButtonType.secondary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  factory CoreButton.outline({
    required String text,
    VoidCallback? onPressed,
    CoreButtonSize size = CoreButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return CoreButton(
      text: text,
      onPressed: onPressed,
      type: CoreButtonType.outline,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  factory CoreButton.text({
    required String text,
    VoidCallback? onPressed,
    CoreButtonSize size = CoreButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return CoreButton(
      text: text,
      onPressed: onPressed,
      type: CoreButtonType.text,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  factory CoreButton.danger({
    required String text,
    VoidCallback? onPressed,
    CoreButtonSize size = CoreButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return CoreButton(
      text: text,
      onPressed: onPressed,
      type: CoreButtonType.danger,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = _getButtonStyle(theme);
    final textStyle = _getTextStyle(theme);

    Widget buttonChild =
        child ??
        Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && !isLoading) ...[
              Icon(icon, size: _getIconSize()),
              const SizedBox(width: 8),
            ],
            if (isLoading) ...[
              SizedBox(
                width: _getIconSize(),
                height: _getIconSize(),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(text, style: textStyle),
          ],
        );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getButtonHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonChild,
      ),
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseStyle = ElevatedButton.styleFrom(
      padding: _getPadding(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: type == CoreButtonType.text ? 0 : 2,
    );

    switch (type) {
      case CoreButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
        );
      case CoreButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.secondary),
          foregroundColor: WidgetStateProperty.all(
            theme.colorScheme.onSecondary,
          ),
        );
      case CoreButtonType.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
          side: WidgetStateProperty.all(
            BorderSide(color: theme.colorScheme.primary),
          ),
          elevation: WidgetStateProperty.all(0),
        );
      case CoreButtonType.text:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
          elevation: WidgetStateProperty.all(0),
        );
      case CoreButtonType.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.red),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = theme.textTheme.labelLarge ?? const TextStyle();

    switch (size) {
      case CoreButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case CoreButtonSize.medium:
        return baseStyle.copyWith(fontSize: 14);
      case CoreButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case CoreButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CoreButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case CoreButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case CoreButtonSize.small:
        return 32;
      case CoreButtonSize.medium:
        return 48;
      case CoreButtonSize.large:
        return 56;
    }
  }

  double _getIconSize() {
    switch (size) {
      case CoreButtonSize.small:
        return 16;
      case CoreButtonSize.medium:
        return 20;
      case CoreButtonSize.large:
        return 24;
    }
  }
}
