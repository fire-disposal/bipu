import 'package:flutter/material.dart';

class SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Column(
              children: children.asMap().entries.map((entry) {
                final index = entry.key;
                final widget = entry.value;
                final isLast = index == children.length - 1;

                if (isLast) return widget;
                return Column(
                  children: [
                    widget,
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 13))
          : null,
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}
