import 'package:flutter/material.dart';

/// 管理端基础布局，包含侧边栏、顶部栏、内容区
class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? drawer;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: actions,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 1,
      ),
      drawer: drawer,
      body: SafeArea(child: child),
    );
  }
}
