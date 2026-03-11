import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/pager_vm.dart';
import '../state/pager_phase.dart';
import 'realtime_waveform_widget.dart';

/// 新架构通话中视图
/// 支持完整的交互流程：输入ID → 确认ID → 录音 → 确认消息
class NewInCallView extends StatefulWidget {
  const NewInCallView({super.key});

  @override
  State<NewInCallView> createState() => _NewInCallViewState();
}

class _NewInCallViewState extends State<NewInCallView> {
  late TextEditingController _targetIdController;

  @override
  void initState() {
    super.initState();
    _targetIdController = TextEditingController();
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NewInCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vm = Provider.of<PagerVM>(context, listen: false);
    if (_targetIdController.text.isNotEmpty && vm.targetId.isEmpty) {
      _targetIdController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagerVM>();
    final cs = Theme.of(context).colorScheme;
    final op = vm.operator;
    final themeColor = op?.themeColor ?? cs.primary;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(cs, themeColor, vm.inCallSubPhase),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                    _buildOperatorInfo(context, op, cs, vm.currentDialogue),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                    _buildSubPhaseContent(vm, cs, themeColor),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, Color themeColor, InCallSubPhase subPhase) {
    String statusText = switch (subPhase) {
      InCallSubPhase.inputTarget => '等待输入号码',
      InCallSubPhase.confirmTarget => '确认目标用户',
      InCallSubPhase.recording => '录音录入消息',
      InCallSubPhase.confirmMessage => '确认消息内容',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Icon(
            Icons.signal_cellular_4_bar,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showHangupDialog(cs),
            child: Icon(
              Icons.call_end_rounded,
              size: 20,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showHangupDialog(ColorScheme cs) {
    final vm = context.read<PagerVM>();
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

  Widget _buildOperatorInfo(
    BuildContext context,
    dynamic op,
    ColorScheme cs,
    String currentDialogue,
  ) {
    if (op == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                op.portraitUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: cs.surfaceContainerHighest),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            op.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentDialogue.isNotEmpty ? currentDialogue : '请输入目标用户号码',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据子阶段显示不同的UI内容
  Widget _buildSubPhaseContent(PagerVM vm, ColorScheme cs, Color themeColor) {
    return switch (vm.inCallSubPhase) {
      InCallSubPhase.inputTarget => _buildInputTargetPanel(vm, cs, themeColor),
      InCallSubPhase.confirmTarget => _buildConfirmTargetPanel(vm, cs, themeColor),
      InCallSubPhase.recording => _buildRecordingPanel(vm, cs, themeColor),
      InCallSubPhase.confirmMessage => _buildConfirmMessagePanel(vm, cs, themeColor),
    };
  }

  // ========== 输入目标ID面板 ==========
  Widget _buildInputTargetPanel(PagerVM vm, ColorScheme cs, Color themeColor) {
    // 同步 controller
    if (_targetIdController.text != vm.targetId) {
      _targetIdController.text = vm.targetId;
      _targetIdController.selection = TextSelection.fromPosition(
        TextPosition(offset: vm.targetId.length),
      );
    }

    final canSubmit = !vm.isConfirming && vm.targetId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextField(
            controller: _targetIdController,
            onChanged: vm.updateTargetId,
            decoration: InputDecoration(
              hintText: '输入目标用户号码',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: canSubmit ? vm.submitTargetId : null,
              icon: vm.isConfirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.check),
              label: Text(vm.isConfirming ? '确认中...' : '确认号码'),
              style: FilledButton.styleFrom(
                backgroundColor: themeColor,
                disabledBackgroundColor: themeColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              vm.errorMessage!,
              style: TextStyle(color: cs.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ========== 确认目标ID面板 ==========
  Widget _buildConfirmTargetPanel(PagerVM vm, ColorScheme cs, Color themeColor) {
    final targetUser = vm.targetUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '确认发送给',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (targetUser != null) ...[
                  if (targetUser.avatarUrl != null) ...[
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(targetUser.avatarUrl!),
                      backgroundColor: cs.surfaceContainerHighest,
                      onBackgroundImageError: (_, __) {},
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (targetUser.nickname != null && targetUser.nickname!.isNotEmpty)
                    Text(
                      targetUser.nickname!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  if (targetUser.username.isNotEmpty)
                    Text(
                      '@${targetUser.username}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    vm.targetId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ] else ...[
                  Text(
                    vm.targetId,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.isConfirming ? null : vm.rejectTargetId,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新输入'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: vm.isConfirming ? null : vm.confirmTargetIdCorrect,
                  icon: vm.isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(vm.isConfirming ? '确认中...' : '确认'),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.errorMessage!,
                      style: TextStyle(color: cs.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========== 录音面板 ==========
  Widget _buildRecordingPanel(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 实时语音输入预览
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: vm.isRecording 
                    ? themeColor.withValues(alpha: 0.5)
                    : themeColor.withValues(alpha: 0.2),
                width: vm.isRecording ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '语音输入预览',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (vm.isRecording) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  vm.asrTranscript.isEmpty 
                      ? (vm.isRecording ? '正在识别...' : '按住麦克风说话')
                      : vm.asrTranscript,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: vm.asrTranscript.isEmpty 
                        ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                        : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 实时波形显示
          if (vm.isRecording)
            Container(
              width: double.infinity,
              height: 80,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RealtimeWaveformWidget(
                amplitudes: vm.realtimeAmplitudes,
                isRecording: vm.isRecording,
                waveColor: themeColor,
                height: 80,
              ),
            ),
          
          // 录音按钮
          _buildRecordingButton(vm, cs, themeColor),
          
          const SizedBox(height: 20),
          
          // 提示文字
          Text(
            vm.isRecording ? '录音中，松开结束' : '按住麦克风按钮开始录音',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 切换文字输入
          TextButton.icon(
            onPressed: vm.isRecording ? null : vm.switchToTextInput,
            icon: const Icon(Icons.keyboard),
            label: const Text('切换文字输入'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(PagerVM vm, ColorScheme cs, Color themeColor) {
    return GestureDetector(
      onTapDown: (_) {
        if (!vm.isRecording) {
          vm.startVoiceRecording();
        }
      },
      onTapUp: (_) {
        if (vm.isRecording) {
          vm.stopRecording();
        }
      },
      onTapCancel: () {
        if (vm.isRecording) {
          vm.stopRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: vm.isRecording ? 80 : 72,
        height: vm.isRecording ? 80 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: vm.isRecording 
              ? Colors.red.withValues(alpha: 0.1)
              : themeColor.withValues(alpha: 0.1),
          border: Border.all(
            color: vm.isRecording ? Colors.red : themeColor,
            width: vm.isRecording ? 3 : 2,
          ),
          boxShadow: [
            if (vm.isRecording)
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: vm.isRecording
                ? Icon(
                    Icons.mic,
                    size: 48,
                    color: Colors.red,
                  )
                : Icon(
                    Icons.mic_none,
                    size: 40,
                    color: themeColor,
                  ),
          ),
        ),
      ),
    );
  }

  // ========== 确认消息面板 ==========
  Widget _buildConfirmMessagePanel(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 消息内容卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: vm.hasEmoji 
                    ? Colors.orange.withValues(alpha: 0.5)
                    : themeColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '消息内容',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (vm.hasEmoji) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '包含表情',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  vm.messageContent.isEmpty ? '（无内容）' : vm.messageContent,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.rerecordMessage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新录制'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: vm.confirmMessageContent,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('确认发送'),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 文字编辑选项
          TextButton.icon(
            onPressed: vm.switchToTextInput,
            icon: const Icon(Icons.edit),
            label: const Text('文字编辑'),
          ),
        ],
      ),
    );
  }
}
