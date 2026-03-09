import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/pager_vm.dart';
import 'state/pager_phase.dart';
import 'widgets/new_prep_view.dart';
import 'widgets/new_connecting_view.dart';
import 'widgets/new_in_call_view.dart';
import 'widgets/new_reviewing_view.dart';
import 'widgets/new_operator_gallery_view.dart';

/// Pager 页面 - 新架构版本
/// 使用 PagerVM 替代 PagerCubit，简化状态管理
class NewPagerPage extends StatelessWidget {
  const NewPagerPage({super.key});

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
    return WillPopScope(
      onWillPop: () => _handleBack(context),
      child: const _PagerScaffold(),
    );
  }

  Future<bool> _handleBack(BuildContext context) async {
    final vm = context.read<PagerVM>();

    // 如果在通话中（连接、输入、确认阶段），需要确认挂断
    if (vm.phase != PagerPhase.prep) {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('确认挂断'),
          content: const Text('返回将挂断当前通话，确定要返回吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('继续通话'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('确认返回'),
            ),
          ],
        ),
      );

      if (result == true) {
        await vm.hangup();
        return true;
      }
      return false;
    }

    // Prep 阶段可以正常返回
    return true;
  }
}

class _PagerScaffold extends StatelessWidget {
  const _PagerScaffold();

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
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: switch (vm.phase) {
          PagerPhase.prep => const NewPrepView(key: ValueKey('prep')),
          PagerPhase.connecting => const NewConnectingView(
            key: ValueKey('connecting'),
          ),
          PagerPhase.inCall => const NewInCallView(key: ValueKey('in_call')),
          PagerPhase.reviewing => const NewReviewingView(
            key: ValueKey('reviewing'),
          ),
        },
      ),
    );
  }

  void _navigateToGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NewOperatorGalleryView()),
    );
  }
}
