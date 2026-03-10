import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/app_state_management.dart';
import '../pager/state/pager_vm.dart';
import '../pager/state/pager_phase.dart';
import 'enhanced_bottom_navigation.dart';

/// 新架构主布局 - 使用 PagerVM
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    super.initState();
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/pager')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    _onItemTappedAsync(index, context);
  }

  Future<void> _onItemTappedAsync(int index, BuildContext context) async {
    final uiCubit = StateProviders.getUiCubit(context);
    uiCubit.updateBottomNavIndex(index);

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/pager');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  /// 长按传呼按钮：跳转到 pager 页面并直接开始拨号
  Future<void> _onPagerLongPressed(BuildContext context) async {
    // 先跳转到 pager 页面
    if (!GoRouterState.of(context).uri.path.startsWith('/pager')) {
      context.go('/pager');
    }

    // 延迟一帧后开始拨号（确保页面已渲染）
    await Future.delayed(const Duration(milliseconds: 100));

    // 获取 PagerVM 单例并开始拨号
    final pagerVm = PagerVM.instance;
    if (pagerVm.phase == PagerPhase.prep) {
      await pagerVm.startDialing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: EnhancedBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        onPagerLongPress: () => _onPagerLongPressed(context),
      ),
    );
  }
}
