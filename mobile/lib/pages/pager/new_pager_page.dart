import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/pager_vm.dart';
import 'state/pager_phase.dart';
import 'widgets/new_prep_view.dart';
import 'widgets/new_connecting_view.dart';
import 'widgets/new_in_call_view.dart';
import 'widgets/new_reviewing_view.dart';

/// Pager 页面 - 新架构版本
/// 使用 PagerVM 替代 PagerCubit，简化状态管理
class PagerPage extends StatelessWidget {
  const PagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: PagerVM.instance,
      child: const _PagerView(),
    );
  }
}

class _PagerView extends StatelessWidget {
  const _PagerView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagerVM>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('虚拟接线员'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark),
            onPressed: () => _navigateToGallery(context),
            tooltip: '接线员图鉴',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        child: switch (vm.phase) {
          PagerPhase.prep => const NewPrepView(key: ValueKey('prep')),
          PagerPhase.connecting => const NewConnectingView(key: ValueKey('connecting')),
          PagerPhase.inCall => NewInCallView(key: const ValueKey('in_call')),
          PagerPhase.reviewing => const NewReviewingView(key: ValueKey('reviewing')),
        },
      ),
    );
  }

  void _navigateToGallery(BuildContext context) {
    // TODO: 实现图鉴页面导航
  }
}
