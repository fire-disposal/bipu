import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/design_system.dart';
import '../logic/pager_notifier.dart';
import 'widgets/waveform_view.dart';

/// 传唤台主页
class PagerScreen extends HookConsumerWidget {
  const PagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagerState = ref.watch(pagerNotifierProvider);
    final pagerMode = ref.watch(pagerModeProvider);
    final notifier = ref.read(pagerNotifierProvider.notifier);

    // 目标 ID 输入控制器
    final targetController = useTextEditingController();
    final messageController = useTextEditingController();

    void handleCall() {
      final targetId = targetController.text.trim();
      if (targetId.isEmpty) return;
      notifier.startCalling(targetId);
    }

    void handleHangup() {
      notifier.hangup();
    }

    void handleToggleMode() {
      notifier.toggleMode();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('传唤台'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // 模式切换按钮
          IconButton(
            icon: Icon(
              pagerMode == PagerMode.voice ? Icons.mic : Icons.keyboard,
            ),
            tooltip: pagerMode == PagerMode.voice ? '语音模式' : '手动模式',
            onPressed: handleToggleMode,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // 状态指示器
              _buildStatusIndicator(context, pagerState),

              const SizedBox(height: AppSpacing.xxl),

              // 根据状态显示不同内容
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContent(
                    context,
                    ref,
                    pagerState,
                    pagerMode,
                    targetController,
                    messageController,
                    notifier,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 操作按钮
              _buildActionButtons(
                context,
                pagerState,
                handleCall,
                handleHangup,
                notifier,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, PagerState state) {
    final theme = Theme.of(context);

    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (state) {
      case PagerState.idle:
        statusText = '待机中';
        statusIcon = Icons.pause_circle_outline;
        statusColor = theme.colorScheme.outline;
        break;
      case PagerState.calling:
        statusText = '呼叫中...';
        statusIcon = Icons.phone_in_talk;
        statusColor = theme.colorScheme.primary;
        break;
      case PagerState.recording:
        statusText = '录音中';
        statusIcon = Icons.mic;
        statusColor = theme.colorScheme.error;
        break;
      case PagerState.manual:
        statusText = '手动模式';
        statusIcon = Icons.keyboard;
        statusColor = theme.colorScheme.secondary;
        break;
      case PagerState.connected:
        statusText = '通话中';
        statusIcon = Icons.phone_enabled;
        statusColor = theme.colorScheme.tertiary;
        break;
    }

    return FadeIn(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PagerState state,
    PagerMode mode,
    targetController,
    messageController,
    PagerNotifier notifier,
  ) {
    switch (state) {
      case PagerState.idle:
        return _buildIdleContent(context, targetController);

      case PagerState.calling:
        return _buildCallingContent(context);

      case PagerState.recording:
        return _buildRecordingContent(context, notifier);

      case PagerState.manual:
      case PagerState.connected:
        return _buildManualContent(context, messageController, notifier);
    }
  }

  Widget _buildIdleContent(BuildContext context, targetController) {
    return FadeInUp(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '输入目标 ID 开始传唤',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 300,
            child: ShadInput(
              controller: targetController,
              placeholder: const Text('Bipupu ID 或服务号'),
              textInputAction: TextInputAction.done,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingContent(BuildContext context) {
    return FadeIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('正在呼叫目标...', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '请等待连接',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingContent(BuildContext context, PagerNotifier notifier) {
    return FadeIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 声纹波形
          const SizedBox(width: 200, height: 100, child: WaveformView()),
          const SizedBox(height: AppSpacing.xl),
          Text('正在录音...', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          ShadButton.destructive(
            onPressed: notifier.stopRecording,
            child: const Text('停止录音'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualContent(
    BuildContext context,
    messageController,
    PagerNotifier notifier,
  ) {
    return FadeInUp(
      child: Column(
        children: [
          Text('输入要发送的消息', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          ShadInput(
            controller: messageController,
            placeholder: const Text('输入消息内容...'),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          ShadButton(
            onPressed: () {
              final content = messageController.text.trim();
              if (content.isEmpty) return;
              notifier.sendMessage(content);
              messageController.clear();
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PagerState state,
    VoidCallback handleCall,
    VoidCallback handleHangup,
    PagerNotifier notifier,
  ) {
    switch (state) {
      case PagerState.idle:
        return SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: handleCall,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call, size: 18),
                SizedBox(width: 8),
                Text('呼叫'),
              ],
            ),
          ),
        );

      case PagerState.calling:
        return Row(
          children: [
            Expanded(
              child: ShadButton.secondary(
                onPressed: notifier.startRecording,
                child: const Text('录音'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ShadButton(
                onPressed: notifier.switchToManual,
                child: const Text('手动'),
              ),
            ),
          ],
        );

      case PagerState.recording:
      case PagerState.manual:
      case PagerState.connected:
        return SizedBox(
          width: double.infinity,
          child: ShadButton.destructive(
            onPressed: handleHangup,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_end, size: 18),
                SizedBox(width: 8),
                Text('挂断'),
              ],
            ),
          ),
        );
    }
  }
}
