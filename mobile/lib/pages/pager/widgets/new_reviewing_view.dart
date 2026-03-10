import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/pager_vm.dart';
import '../widgets/waveform_visualization_widget.dart';

/// 新架构确认视图
/// 支持消息编辑、波形预览和返回修改
class NewReviewingView extends StatefulWidget {
  const NewReviewingView({super.key});

  @override
  State<NewReviewingView> createState() => _NewReviewingViewState();
}

class _NewReviewingViewState extends State<NewReviewingView> {
  late TextEditingController _messageController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagerVM>();
    final cs = Theme.of(context).colorScheme;
    final op = vm.operator;
    final themeColor = op?.themeColor ?? cs.primary;

    // 同步控制器内容
    if (!_isEditing && _messageController.text != vm.messageContent) {
      _messageController.text = vm.messageContent;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(cs, themeColor, vm),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTargetInfo(vm, cs, themeColor),
                      const SizedBox(height: 20),
                      _buildMessageSection(vm, cs, themeColor),
                      if (vm.capturedWaveform != null) ...[
                        const SizedBox(height: 20),
                        _buildWaveformSection(vm, cs, themeColor),
                      ],
                      if (vm.hasEmoji) ...[
                        const SizedBox(height: 16),
                        _buildEmojiWarning(cs),
                      ],
                    ],
                  ),
                ),
              ),
              _buildActionButtons(vm, cs, themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, Color themeColor, PagerVM vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 返回按钮
        IconButton(
          onPressed: vm.isSending ? null : () => vm.backToEditMessage(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回修改',
        ),
        // 标题
        Text(
          '最终确认',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        // 挂断按钮
        GestureDetector(
          onTap: () => _showHangupDialog(context, vm),
          child: Icon(
            Icons.call_end_rounded,
            size: 24,
            color: Colors.red.shade600,
          ),
        ),
      ],
    );
  }

  void _showHangupDialog(BuildContext context, PagerVM vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认挂断'),
        content: const Text('是否确定要挂断通话？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续通话'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              vm.hangup();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('挂断'),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInfo(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '目标',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              vm.targetId,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '消息内容',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: vm.isSending
                    ? null
                    : () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            // 保存编辑内容
                            vm.updateMessageContent(_messageController.text);
                          }
                        });
                      },
                icon: Icon(_isEditing ? Icons.check : Icons.edit),
                label: Text(_isEditing ? '完成' : '编辑'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isEditing
              ? TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: '输入消息内容',
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vm.messageContent.isEmpty ? '（无内容）' : vm.messageContent,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWaveformSection(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '语音波形',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: WaveformVisualizationWidget(
              waveformData: vm.capturedWaveform!,
              width: double.infinity,
              height: 100,
              waveColor: themeColor,
              showGrid: false,
              showLabels: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiWarning(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '消息包含表情符号，可能会被过滤',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 发送按钮
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: vm.isSending ? null : () => vm.sendMessage(),
            icon: vm.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.send),
            label: Text(vm.isSending ? '发送中...' : '确认发送'),
            style: FilledButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 返回修改按钮
        OutlinedButton.icon(
          onPressed: vm.isSending ? null : () => vm.backToEditMessage(),
          icon: const Icon(Icons.refresh),
          label: const Text('返回修改'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
