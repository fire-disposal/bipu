import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/pager_vm.dart';
import '../state/pager_phase.dart';
import 'realtime_waveform_widget.dart';
import 'waveform_visualization_widget.dart';

/// 通话中视图
/// 五个子阶段面板（inputTarget / confirmTarget / recording /
/// confirmMessage / reviewing）均显示在接线员头像下方，风格统一。
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

    // 目标 ID 控制器同步
    if (_targetIdController.text.isNotEmpty && vm.targetId.isEmpty) {
      _targetIdController.clear();
    }

    // 进入 confirmMessage / reviewing 时填充消息内容
    final isMessagePhase =
        vm.inCallSubPhase == InCallSubPhase.confirmMessage ||
        vm.inCallSubPhase == InCallSubPhase.reviewing;
    if (isMessagePhase &&
        _messageController.text.isEmpty &&
        vm.messageContent.isNotEmpty) {
      _messageController.text = vm.messageContent;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: vm.messageContent.length),
      );
    }

    // 返回录音时清空消息控制器
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
            _buildTopBar(cs, themeColor, vm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    _buildOperatorInfo(context, op, cs, vm.currentDialogue),
                    const SizedBox(height: 28),
                    _buildSubPhaseContent(vm, cs, themeColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 顶部状态栏
  // ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(ColorScheme cs, Color themeColor, PagerVM vm) {
    final (statusText, stepText) = switch (vm.inCallSubPhase) {
      InCallSubPhase.inputTarget => ('输入目标号码', '1 / 3'),
      InCallSubPhase.confirmTarget => ('确认目标用户', '1 / 3'),
      InCallSubPhase.recording => ('录入传呼消息', '2 / 3'),
      InCallSubPhase.confirmMessage => ('确认消息内容', '2 / 3'),
      InCallSubPhase.reviewing => ('确认发送', '3 / 3'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          // 呼叫指示灯
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
          const SizedBox(width: 10),
          Text(
            statusText,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          // 步骤胶囊
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stepText,
              style: TextStyle(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.signal_cellular_4_bar,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
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
      builder: (ctx) => AlertDialog(
        title: const Text('确认挂断'),
        content: const Text('是否确定要挂断通话？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续通话'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.hangup();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('挂断'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 接线员头像 + 台词框
  // ─────────────────────────────────────────────────────────────────

  Widget _buildOperatorInfo(
    BuildContext context,
    dynamic op,
    ColorScheme cs,
    String currentDialogue,
  ) {
    if (op == null) return const SizedBox.shrink();

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
          // 圆形头像
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: imageWidget),
          ),
          const SizedBox(height: 12),
          Text(
            op.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // 台词气泡
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              currentDialogue.isNotEmpty ? currentDialogue : '…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 子阶段路由
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSubPhaseContent(PagerVM vm, ColorScheme cs, Color themeColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(vm.inCallSubPhase),
        child: switch (vm.inCallSubPhase) {
          InCallSubPhase.inputTarget => _buildInputTargetPanel(
            vm,
            cs,
            themeColor,
          ),
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
          InCallSubPhase.reviewing => _buildReviewingPanel(vm, cs, themeColor),
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 通用：分区卡片 / 标签 / 错误卡 / 表情警告
  // ─────────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required ColorScheme cs,
    required Widget child,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? cs.outlineVariant.withValues(alpha: 0.35),
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String label) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _errorCard(String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiWarningCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
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
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required Widget icon,
    required VoidCallback? onPressed,
    required Color themeColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: themeColor,
          disabledBackgroundColor: themeColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 阶段 1a：输入目标号码
  // ─────────────────────────────────────────────────────────────────

  Widget _buildInputTargetPanel(PagerVM vm, ColorScheme cs, Color themeColor) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('目标用户号码'),
          const SizedBox(height: 8),
          TextField(
            controller: _targetIdController,
            onChanged: vm.updateTargetId,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (canSubmit) vm.submitTargetId();
            },
            decoration: InputDecoration(
              hintText: '输入对方的用户名或号码',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: themeColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            label: vm.isConfirming ? '确认中…' : '确认号码',
            icon: vm.isConfirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            onPressed: canSubmit ? vm.submitTargetId : null,
            themeColor: themeColor,
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorCard(vm.errorMessage!),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 阶段 1b：确认目标用户
  // ─────────────────────────────────────────────────────────────────

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
          _sectionCard(
            cs: cs,
            borderColor: themeColor.withValues(alpha: 0.3),
            borderWidth: 1.5,
            child: Column(
              children: [
                _sectionLabel('确认发送目标'),
                const SizedBox(height: 14),
                if (targetUser != null) ...[
                  if (targetUser.avatarUrl != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(targetUser.avatarUrl!),
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  const SizedBox(height: 8),
                  if (targetUser.nickname?.isNotEmpty == true)
                    Text(
                      targetUser.nickname!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    '@${targetUser.username}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vm.targetId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ] else ...[
                  Text(
                    vm.targetId,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  label: '重新输入',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: vm.isConfirming ? null : vm.rejectTargetId,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _primaryButton(
                  label: vm.isConfirming ? '确认中…' : '就是他',
                  icon: vm.isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                  onPressed: vm.isConfirming ? null : vm.confirmTargetIdCorrect,
                  themeColor: themeColor,
                ),
              ),
            ],
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorCard(vm.errorMessage!),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 阶段 2a：录音
  // ─────────────────────────────────────────────────────────────────

  Widget _buildRecordingPanel(PagerVM vm, ColorScheme cs, Color themeColor) {
    final hasTranscript = vm.asrTranscript.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ASR 实时文字预览
          _sectionCard(
            cs: cs,
            borderColor: vm.isRecording
                ? themeColor.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.35),
            borderWidth: vm.isRecording ? 1.5 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Container(
                      width: 7,
                      height: 7,
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
                        ? '正在识别中…'
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
          const SizedBox(height: 14),

          // 波形（录音时展开）
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: vm.isRecording
                ? Container(
                    width: double.infinity,
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RealtimeWaveformWidget(
                      amplitudes: vm.realtimeAmplitudes,
                      isRecording: vm.isRecording,
                      waveColor: themeColor,
                      height: 52,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 麦克风按钮
          _buildMicButton(vm, cs, themeColor),
          const SizedBox(height: 8),
          Text(
            vm.isRecording ? '录音中 · 再次轻触停止' : '轻触开始录音',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: vm.isRecording ? Colors.red.shade400 : cs.onSurfaceVariant,
              fontWeight: vm.isRecording ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 18),

          // 文字输入备选
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

          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorCard(vm.errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildMicButton(PagerVM vm, ColorScheme cs, Color themeColor) {
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
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 22,
                spreadRadius: 5,
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

  // ─────────────────────────────────────────────────────────────────
  // 阶段 2b：确认消息内容（可编辑）
  // ─────────────────────────────────────────────────────────────────

  Widget _buildConfirmMessagePanel(
    PagerVM vm,
    ColorScheme cs,
    Color themeColor,
  ) {
    if (_messageController.text.isEmpty && vm.messageContent.isNotEmpty) {
      _messageController.text = vm.messageContent;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: vm.messageContent.length),
      );
    }

    const int maxLength = 200;
    final int len = _messageController.text.length;
    final bool isOverLimit = len > maxLength;
    final bool canSend = len > 0 && !isOverLimit && !vm.hasEmoji;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('消息内容'),
              const Spacer(),
              Text(
                '$len\u00a0/\u00a0$maxLength',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOverLimit
                      ? cs.error
                      : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              hintText: '输入消息内容…',
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
          if (isOverLimit) ...[
            const SizedBox(height: 6),
            Text(
              '消息过长，请精简到 $maxLength 字以内',
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
          if (vm.hasEmoji) ...[const SizedBox(height: 10), _emojiWarningCard()],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  label: '重新录制',
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  onPressed: vm.rerecordMessage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _primaryButton(
                  label: '下一步',
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  onPressed: canSend ? vm.confirmMessageContent : null,
                  themeColor: themeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 阶段 3：最终确认发送
  // ─────────────────────────────────────────────────────────────────

  Widget _buildReviewingPanel(PagerVM vm, ColorScheme cs, Color themeColor) {
    final targetUser = vm.targetUser;
    final targetName = targetUser?.nickname?.isNotEmpty == true
        ? targetUser!.nickname!
        : (targetUser?.username.isNotEmpty == true
              ? '@${targetUser!.username}'
              : vm.targetId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 发送目标摘要 ──────────────────────────
          _sectionLabel('发送给'),
          const SizedBox(height: 8),
          _sectionCard(
            cs: cs,
            borderColor: themeColor.withValues(alpha: 0.3),
            borderWidth: 1.5,
            child: Row(
              children: [
                // 头像
                if (targetUser?.avatarUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(targetUser!.avatarUrl!),
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: themeColor.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_outline,
                        size: 18,
                        color: themeColor,
                      ),
                    ),
                  ),
                // 姓名 + 用户名
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (targetUser?.username.isNotEmpty == true &&
                          targetUser?.nickname?.isNotEmpty == true)
                        Text(
                          '@${targetUser!.username}  ·  ${vm.targetId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: themeColor, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── 消息内容摘要 ──────────────────────────
          _sectionLabel('消息内容'),
          const SizedBox(height: 8),
          _sectionCard(
            cs: cs,
            child: Text(
              vm.messageContent.isNotEmpty ? vm.messageContent : '（无内容）',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurface, height: 1.6),
            ),
          ),

          // ── 波形预览（可选）────────────────────────
          if (vm.capturedWaveform != null &&
              vm.capturedWaveform!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionLabel('语音波形'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                child: WaveformVisualizationWidget(
                  waveformData: vm.capturedWaveform!,
                  width: double.infinity,
                  height: 72,
                  waveColor: themeColor,
                  showGrid: false,
                  showLabels: false,
                ),
              ),
            ),
          ],

          // ── 表情警告 ──────────────────────────────
          if (vm.hasEmoji) ...[const SizedBox(height: 12), _emojiWarningCard()],

          const SizedBox(height: 20),

          // ── 操作按钮 ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  label: '返回修改',
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: vm.isSending ? null : vm.backToEditMessage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _primaryButton(
                  label: vm.isSending ? '发送中…' : '确认发送',
                  icon: vm.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  onPressed: vm.isSending || vm.hasEmoji
                      ? null
                      : vm.sendMessage,
                  themeColor: themeColor,
                ),
              ),
            ],
          ),

          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorCard(vm.errorMessage!),
          ],
        ],
      ),
    );
  }
}
