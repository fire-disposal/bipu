import 'package:flutter/material.dart';
import 'admin_sidebar.dart';

/// 管理端完整布局脚手架，包含侧边栏、顶部栏、内容区
class AdminScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final int selectedIndex;
  final Function(int)? onNavigationChanged;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AdminScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    required this.selectedIndex,
    this.onNavigationChanged,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: AdminSidebar(
              selectedIndex: widget.selectedIndex,
              onItemSelected: (index) {
                widget.onNavigationChanged?.call(index);
              },
            ),
          ),
          // 主内容区
          Expanded(
            child: Column(
              children: [
                // 顶部工具栏
                _buildAppBar(context),
                // 内容区域
                Expanded(
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 标题
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // 搜索框
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 操作按钮
          if (widget.actions != null) ...widget.actions!,
          // 用户头像
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
