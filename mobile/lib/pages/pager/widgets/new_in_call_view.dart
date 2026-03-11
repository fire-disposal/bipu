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
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _targetIdController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NewInCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vm = Provider.of<PagerVM>(context, listen: false);
    // 处理目标ID控制器
    if (_targetIdController.text.isNotEmpty && vm.targetId.isEmpty) {
      _targetIdController.clear();
    }
    // 切入 confirmMessage 子阶段时，将 ASR 识别结果填入消息控制器
    if (vm.inCallSubPhase == InCallSubPhase.confirmMessage &&
        _messageController.text.isEmpty &&
        vm.messageContent.isNotEmpty) {
      _messageController.text = vm.messageContent;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: vm.messageContent.length),
      );
    }
    // 回到录音阶段时清空消息控制器
    if (vm.inCallSubPhase == InCallSubPhase.recording &&
        vm.messageContent.isEmpty) {
      _messageController.clear();
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

  Widget _buildTopBar(
    ColorScheme cs,
    Color themeColor,
    InCallSubPhase subPhase,
  ) {
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

    // 根据URL类型选择正确的图片加载方式
    final isNetworkImage = op.portraitUrl.startsWith('http');
    final imageWidget = isNetworkImage
        ? Image.network(
            op.portraitUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: cs.surfaceContainerHighest),
          )
        : Image.asset(
            op.portraitUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: cs.surfaceContainerHighest),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 1:1 圆形头像，圆角90°
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: imageWidget),
          ),
          const SizedBox(height: 16),
          Text(
            op.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
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
      InCallSubPhase.confirmTarget => _buildConfirmTargetPanel(
        vm,
        cs,
        themeColor,
      ),
      InCallSubPhase.recording => _buildRecordingPanel(vm, cs, themeColor),
      InCallSubPhase.confirmMessage => _buildConfirmMessagePanel(
        vm,
        cs,
        themeColor,
      ),
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
  Widget _buildConfirmTargetPanel(
    PagerVM vm,
    ColorScheme cs,
    Color themeColor,
  ) {
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
                  if (targetUser.nickname != null &&
                      targetUser.nickname!.isNotEmpty)
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
    final bool hasTranscript = vm.asrTranscript.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ASR 转写预览框
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: vm.isRecording
                    ? themeColor.withValues(alpha: 0.55)
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: vm.isRecording ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    hasTranscript
                        ? vm.asrTranscript
                        : vm.isRecording
                        ? '正在识别中……'
                        : '轻触麦克风按钮开始录音',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: hasTranscript
                          ? cs.onSurface
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontStyle: hasTranscript
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 波形动画区域（仅录音时展开）
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: vm.isRecording
                ? Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RealtimeWaveformWidget(
                      amplitudes: vm.realtimeAmplitudes,
                      isRecording: vm.isRecording,
                      waveColor: themeColor,
                      height: 56,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 麦克风按钮
          _buildRecordingButton(vm, cs, themeColor),

          const SizedBox(height: 10),

          // 状态提示文字
          Text(
            vm.isRecording ? '录音中 · 再次轻触停止' : '轻触开始录音',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: vm.isRecording ? Colors.red.shade400 : cs.onSurfaceVariant,
              fontWeight: vm.isRecording ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 20),

          // 文字输入备选（非录音时显示）
          if (!vm.isRecording)
            OutlinedButton.icon(
              onPressed: vm.switchToTextInput,
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: const Text('文字输入'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // 错误信息
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: cs.error, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
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

  Widget _buildRecordingButton(PagerVM vm, ColorScheme cs, Color themeColor) {
    return GestureDetector(
      onTap: () {
        if (vm.isRecording) {
          vm.stopRecording();
        } else {
          vm.startVoiceRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: vm.isRecording ? 88 : 76,
        height: vm.isRecording ? 88 : 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: vm.isRecording
              ? Colors.red.withValues(alpha: 0.12)
              : themeColor.withValues(alpha: 0.1),
          border: Border.all(
            color: vm.isRecording ? Colors.red : themeColor,
            width: vm.isRecording ? 3 : 2,
          ),
          boxShadow: [
            if (vm.isRecording)
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 6,
              ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: vm.isRecording
                ? const Icon(
                    Icons.stop_rounded,
                    size: 40,
                    color: Colors.red,
                    key: ValueKey('stop'),
                  )
                : Icon(
                    Icons.mic_rounded,
                    size: 36,
                    color: themeColor,
                    key: ValueKey('mic'),
                  ),
          ),
        ),
      ),
    );
  }

  // ========== 确认消息面板 ==========
  Widget _buildConfirmMessagePanel(
    PagerVM vm,
    ColorScheme cs,
    Color themeColor,
  ) {
    // 切入本面板时尝试填充 controller（仅当 controller 为空时）
    if (_messageController.text.isEmpty && vm.messageContent.isNotEmpty) {
      _messageController.text = vm.messageContent;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: vm.messageContent.length),
      );
    }

    const int maxLength = 200;
    final int contentLength = _messageController.text.length;
    final bool isOverLimit = contentLength > maxLength;
    final bool canSend = contentLength > 0 && !isOverLimit && !vm.hasEmoji;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行 + 字数统计
          Row(
            children: [
              Text(
                '消息内容',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$contentLength\u00a0/\u00a0$maxLength',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOverLimit
                      ? cs.error
                      : cs.onSurfaceVariant.withValues(alpha: 0.65),
                  fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 可编辑消息文本框
          TextField(
            controller: _messageController,
            onChanged: (text) {
              vm.updateMessageContent(text);
              setState(() {});
            },
            maxLines: 5,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '输入消息内容……',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isOverLimit
                      ? cs.error.withValues(alpha: 0.6)
                      : themeColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isOverLimit ? cs.error : themeColor,
                  width: 2,
                ),
              ),
            ),
          ),

          // 超出限制警告
          if (isOverLimit) ...[
            const SizedBox(height: 6),
            Text(
              '消息过长，请精简到 $maxLength 字以内',
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],

          // 表情符号警告
          if (vm.hasEmoji) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '传呼机不支持表情符号，请删除后再发送',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.rerecordMessage,
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const Text('重新录制'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: canSend ? vm.confirmMessageContent : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('发送消息'),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor: themeColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
