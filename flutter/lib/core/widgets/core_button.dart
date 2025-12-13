import 'package:flutter/material.dart';

/// 通用按钮组件，支持主色/次色、禁用、加载等状态
class CoreButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool loading;
  final IconData? icon;

  const CoreButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: primary ? colorScheme.primary : colorScheme.secondary,
      foregroundColor: colorScheme.onPrimary,
      minimumSize: const Size(120, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return ElevatedButton.icon(
      style: buttonStyle,
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 2,
              ),
            )
          : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
      label: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
