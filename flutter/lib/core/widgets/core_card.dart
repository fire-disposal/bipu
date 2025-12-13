import 'package:flutter/material.dart';

/// 通用卡片组件，支持阴影、圆角、可自定义内容
class CoreCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double elevation;
  final VoidCallback? onTap;

  const CoreCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    this.color,
    this.elevation = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color ?? Theme.of(context).cardColor,
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
