/// 核心卡片组件
library;

import 'package:flutter/material.dart';

/// 卡片类型
enum CoreCardType { elevated, outlined, filled }

/// 核心卡片组件
class CoreCard extends StatelessWidget {
  final Widget child;
  final CoreCardType type;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasShadow;

  const CoreCard({
    super.key,
    required this.child,
    this.type = CoreCardType.elevated,
    this.elevation = 2,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
    this.hasShadow = true,
  });

  factory CoreCard.elevated({
    required Widget child,
    double elevation = 2,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadius? borderRadius,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return CoreCard(
      child: child,
      type: CoreCardType.elevated,
      elevation: elevation,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }

  factory CoreCard.outlined({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadius? borderRadius,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return CoreCard(
      child: child,
      type: CoreCardType.outlined,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      hasShadow: false,
    );
  }

  factory CoreCard.filled({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadius? borderRadius,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return CoreCard(
      child: child,
      type: CoreCardType.filled,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      hasShadow: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final effectiveBackgroundColor =
        backgroundColor ?? _getBackgroundColor(theme);

    Widget card = Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: _getBorder(theme),
        boxShadow: hasShadow ? _getShadow(theme) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return card;
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (type) {
      case CoreCardType.elevated:
        return theme.colorScheme.surface;
      case CoreCardType.outlined:
        return theme.colorScheme.surface;
      case CoreCardType.filled:
        return theme.colorScheme.surfaceVariant;
    }
  }

  Border? _getBorder(ThemeData theme) {
    switch (type) {
      case CoreCardType.elevated:
      case CoreCardType.filled:
        return null;
      case CoreCardType.outlined:
        return Border.all(color: theme.colorScheme.outline, width: 1);
    }
  }

  List<BoxShadow>? _getShadow(ThemeData theme) {
    if (!hasShadow) return null;

    return [
      BoxShadow(
        color: theme.colorScheme.shadow.withOpacity(0.1),
        blurRadius: elevation * 2,
        spreadRadius: 0,
        offset: Offset(0, elevation),
      ),
    ];
  }
}

/// 统计卡片组件
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CoreCard.elevated(
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 信息卡片组件
class InfoCard extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CoreCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }
}
