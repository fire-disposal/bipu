import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'state/pager_state_machine.dart';
import 'state/pager_cubit.dart';
import 'pages/dialing_prep_page_minimal.dart';
import 'pages/in_call_page.dart';
import 'pages/finalize_page.dart';
import 'pages/operator_gallery_page_new.dart';
import 'services/operator_service.dart';

/// 增强版拨号页面
/// 采用状态机模式，通过 PagerCubit 驱动 UI 切换
class PagerPageEnhanced extends StatefulWidget {
  const PagerPageEnhanced({super.key});

  @override
  State<PagerPageEnhanced> createState() => _PagerPageEnhancedState();
}

class _PagerPageEnhancedState extends State<PagerPageEnhanced> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<PagerCubit>(
      // 这里的 create 确保 Cubit 生命周期与 Widget 绑定
      create: (context) => PagerCubit()..initializeDialingPrep(),
      child: const _PagerView(),
    );
  }
}

class _PagerView extends StatelessWidget {
  const _PagerView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PagerCubit>();

    return BlocListener<PagerCubit, PagerState>(
      // 监听解锁状态和错误状态，触发全局弹窗
      listenWhen: (prev, curr) =>
          curr is OperatorUnlockedState || curr is PagerErrorState,
      listener: (context, state) {
        if (state is OperatorUnlockedState) {
          _showUnlockDialog(context, state);
        } else if (state is PagerErrorState) {
          _showErrorDialog(context, state);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('虚拟接线员'),
          elevation: 0,
          centerTitle: true,
          actions: [
            // 收藏页面入口按钮
            IconButton(
              icon: const Icon(Icons.collections_bookmark),
              onPressed: () => _navigateToGallery(context),
              tooltip: '接线员图鉴',
            ),
          ],
        ),
        body: BlocBuilder<PagerCubit, PagerState>(
          // 重要：当状态为解锁弹窗时，不重新构建 body，保持底层页面不变
          buildWhen: (prev, curr) => curr is! OperatorUnlockedState,
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBody(context, state, cubit),
            );
          },
        ),
      ),
    );
  }

  /// 根据状态分发子页面
  Widget _buildBody(BuildContext context, PagerState state, PagerCubit cubit) {
    if (state is DialingPrepState) {
      return DialingPrepPageMinimal(key: const ValueKey('prep'), cubit: cubit);
    }
    if (state is InCallState) {
      return InCallPage(key: const ValueKey('in_call'), cubit: cubit);
    }
    if (state is FinalizeState) {
      return FinalizePage(key: const ValueKey('finalize'), cubit: cubit);
    }
    if (state is PagerErrorState) {
      return _ErrorDisplay(state: state, onRetry: cubit.initializeDialingPrep);
    }

    return const Center(child: CircularProgressIndicator.adaptive());
  }

  /// 弹出解锁成功对话框
  void _showUnlockDialog(BuildContext context, OperatorUnlockedState state) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部奖励图标
                _buildAwardHeader(colorScheme),
                const SizedBox(height: 20),

                Text(
                  state.unlockMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 操作员名片展示
                _buildOperatorCard(colorScheme, state.operator),
                const SizedBox(height: 24),

                // 交互按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('继续拨号'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _navigateToGallery(context);
                        },
                        child: const Text('查看图鉴'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 弹出错误对话框
  void _showErrorDialog(BuildContext context, PagerErrorState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('拨号错误'),
        content: Text(state.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 返回拨号准备状态
              context.read<PagerCubit>().initializeDialingPrep();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardHeader(ColorScheme colorScheme) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.tertiaryContainer,
      ),
      child: Icon(Icons.stars_rounded, size: 40, color: colorScheme.tertiary),
    );
  }

  Widget _buildOperatorCard(ColorScheme colorScheme, dynamic op) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _buildPortrait(op.portraitUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  op.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  op.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 50,
        height: 65,
        child: url.startsWith('http')
            ? Image.network(url, fit: BoxFit.cover)
            : Image.asset(url, fit: BoxFit.cover),
      ),
    );
  }

  void _navigateToGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OperatorGalleryPageNew(operatorService: OperatorService()),
      ),
    );
  }
}

/// 抽离的错误展示组件
class _ErrorDisplay extends StatelessWidget {
  final PagerErrorState state;
  final VoidCallback onRetry;

  const _ErrorDisplay({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('服务请求失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试一次'),
            ),
          ],
        ),
      ),
    );
  }
}

// 兼容旧类名
class PagerPage extends StatelessWidget {
  const PagerPage({super.key});
  @override
  Widget build(BuildContext context) => const PagerPageEnhanced();
}
