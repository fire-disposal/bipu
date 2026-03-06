import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/app_state_management.dart';
import '../pager/state/pager_cubit.dart';
import '../pager/state/pager_state_machine.dart';
import 'enhanced_bottom_navigation.dart';

/// 重构后的主布局
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  /// PagerCubit 持久化在此层，确保切换 Tab 时通话状态不被销毁
  late final PagerCubit _pagerCubit;

  @override
  void initState() {
    super.initState();
    _pagerCubit = PagerCubit()..initializeDialingPrep();
  }

  @override
  void dispose() {
    _pagerCubit.close();
    super.dispose();
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

  /// 长按传呼按钮：跳转到 pager 页面并立即开始呼叫接线员
  /// 注意：触觉反馈由 _PagerNavButton 的蓄力动画完成时统一触发，此处不再重复
  void _onPagerLongPressed(BuildContext context) {
    // 先导航到 pager 页面
    if (!GoRouterState.of(context).uri.path.startsWith('/pager')) {
      context.go('/pager');
    }

    // 仅在准备阶段（未在通话中）才触发拨号，等效于点击"呼叫接线员"按钮
    final state = _pagerCubit.state;
    if (state is DialingPrepState && !state.isLoading) {
      _pagerCubit.startDialing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return BlocProvider<PagerCubit>.value(
      value: _pagerCubit,
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: EnhancedBottomNavigation(
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(index, context),
          onPagerLongPress: () => _onPagerLongPressed(context),
        ),
      ),
    );
  }
}
