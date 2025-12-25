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
      type: CoreCardType.elevated,
      elevation: elevation,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: child,
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
      type: CoreCardType.outlined,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      hasShadow: false,
      child: child,
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
      type: CoreCardType.filled,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      hasShadow: false,
      child: child,
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
        return theme.colorScheme.surfaceContainerHighest;
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
