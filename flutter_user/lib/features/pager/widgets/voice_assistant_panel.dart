import 'package:flutter/material.dart';
import 'package:bipupu/features/assistant/intent_driven_assistant_controller.dart';
import 'package:bipupu/features/assistant/assistant_config.dart';
import 'operator_gallery.dart';

class VoiceAssistantPanel extends StatefulWidget {
  final IntentDrivenAssistantController assistant;
  final AssistantConfig config;
  final Function(String)? onMessageSent;

  const VoiceAssistantPanel({
    super.key,
    required this.assistant,
    required this.config,
    this.onMessageSent,
  });

  @override
  State<VoiceAssistantPanel> createState() => _VoiceAssistantPanelState();
}

class _VoiceAssistantPanelState extends State<VoiceAssistantPanel> {
  @override
  void initState() {
    super.initState();
    widget.assistant.addListener(_onAssistantUpdate);
  }

  @override
  void dispose() {
    widget.assistant.removeListener(_onAssistantUpdate);
    super.dispose();
  }

  void _onAssistantUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 阶段指示器
          _buildPhaseIndicator(),
          const SizedBox(height: 16),

          // 操作按钮
          _buildActionButtons(),
          const SizedBox(height: 8),

          // 操作员选择
          _buildOperatorSelector(),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    final phase = widget.assistant.currentPhase;
    final phaseInfo = _getPhaseInfo(phase);

    return Column(
      children: [
        LinearProgressIndicator(
          value: phaseInfo.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(phaseInfo.color),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              phaseInfo.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(phaseInfo.progress * 100).toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final availableActions = widget.assistant.availableActions;

    if (availableActions.isEmpty) {
      return const Text('等待中...', style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: availableActions.map((intent) {
        return ElevatedButton(
          onPressed: () => _handleIntent(intent),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(intent),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(_getButtonText(intent)),
        );
      }).toList(),
    );
  }

  Widget _buildOperatorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person_outline, size: 16),
        const SizedBox(width: 4),
        Text(
          '操作员: ${widget.assistant.currentOperatorId}',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _selectOperator(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: const Text('更换', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _handleIntent(UserIntent intent) async {
    try {
      await widget.assistant.handleIntent(intent);

      // 如果消息发送成功，触发回调
      if (intent == UserIntent.send && widget.onMessageSent != null) {
        final text = widget.assistant.currentText;
        if (text != null && text.isNotEmpty) {
          widget.onMessageSent!(text);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  Future<void> _selectOperator() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OperatorGallery()));

    if (mounted) {
      setState(() {});
    }
  }

  // 辅助方法
  _PhaseInfo _getPhaseInfo(AssistantPhase phase) {
    String label;
    double progress;
    Color color;

    switch (phase) {
      case AssistantPhase.greeting:
        label = '初始化引导';
        progress = 0.0;
        color = Colors.blue;
        break;
      case AssistantPhase.askRecipientId:
        label = '请提供收信方ID';
        progress = 0.125;
        color = Colors.blue;
        break;
      case AssistantPhase.confirmRecipientId:
        label = '请确认收信方ID';
        progress = 0.25;
        color = Colors.blue;
        break;
      case AssistantPhase.guideRecordMessage:
      case AssistantPhase.recording:
        label = '正在录音';
        progress = 0.5;
        color = Colors.orange;
        break;
      case AssistantPhase.transcribing:
        label = '转写中';
        progress = 0.625;
        color = Colors.orange;
        break;
      case AssistantPhase.confirmMessage:
        label = '请确认消息';
        progress = 0.75;
        color = Colors.green;
        break;
      case AssistantPhase.sending:
        label = '发送中';
        progress = 0.875;
        color = Colors.green;
        break;
      case AssistantPhase.sent:
        label = '已发送';
        progress = 1.0;
        color = Colors.green;
        break;
      case AssistantPhase.farewell:
        label = '结束';
        progress = 1.0;
        color = Colors.grey;
        break;
      case AssistantPhase.error:
        label = '出错';
        progress = 0.0;
        color = Colors.red;
        break;
      case AssistantPhase.idle:
        label = '空闲';
        progress = 0.0;
        color = Colors.grey;
        break;
    }

    return _PhaseInfo(label, progress, color);
  }

  String _getButtonText(UserIntent intent) {
    switch (intent) {
      case UserIntent.confirm:
        return '确认';
      case UserIntent.modify:
        return '修改';
      case UserIntent.cancel:
        return '取消';
      case UserIntent.rerecord:
        return '重录';
      case UserIntent.send:
        return '发送';
      case UserIntent.start:
        return '开始';
      case UserIntent.stop:
        return '停止';
    }
  }

  Color _getButtonColor(UserIntent intent) {
    switch (intent) {
      case UserIntent.confirm:
      case UserIntent.start:
        return Colors.blue;
      case UserIntent.send:
        return Colors.green;
      case UserIntent.cancel:
      case UserIntent.stop:
        return Colors.redAccent;
      case UserIntent.modify:
      case UserIntent.rerecord:
        return Colors.orange;
    }
  }
}

class _PhaseInfo {
  final String label;
  final double progress;
  final Color color;

  _PhaseInfo(this.label, this.progress, this.color);
}
