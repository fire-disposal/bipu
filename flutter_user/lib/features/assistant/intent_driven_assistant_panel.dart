import 'package:flutter/material.dart';
import 'package:bipupu/features/assistant/intent_driven_assistant_controller.dart';
import 'package:bipupu/features/assistant/assistant_config.dart';

/// 阶段信息结构
class PhaseInfo {
  final String label;
  final double progress;
  final Color color;

  PhaseInfo({required this.label, required this.progress, required this.color});
}

/// 意图驱动的语音助手面板
/// 使用统一的意图接口，简化UI逻辑
class IntentDrivenAssistantPanel extends StatefulWidget {
  const IntentDrivenAssistantPanel({super.key});

  @override
  State<IntentDrivenAssistantPanel> createState() =>
      _IntentDrivenAssistantPanelState();
}

class _IntentDrivenAssistantPanelState
    extends State<IntentDrivenAssistantPanel> {
  final IntentDrivenAssistantController _controller =
      IntentDrivenAssistantController();
  final AssistantConfig _config = AssistantConfig();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _controller.currentPhase;
    final availableIntents = _controller.availableIntents;

    // 阶段标签和进度
    final phaseInfo = _getPhaseInfo(currentPhase);
    final progress = phaseInfo.progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 阶段指示器
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseInfo.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        phaseInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // 打开操作员选择
                  _showOperatorSelector(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 当前信息显示
          if (_controller.currentRecipientId != null ||
              _controller.currentText != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_controller.currentRecipientId != null)
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '收信方: ${_controller.currentRecipientId}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  if (_controller.currentText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.message, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '消息: ${_controller.currentText}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 意图按钮
          if (availableIntents.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIntents.map((intent) {
                return ElevatedButton(
                  onPressed: () => _handleIntent(intent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(intent),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(_getButtonText(intent)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 显示操作员选择器
  void _showOperatorSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择操作员',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._config.defaultOperators.map((operator) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: operator.themeColor,
                    child: Text(
                      operator.name.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(operator.name),
                  subtitle: Text(operator.description),
                  trailing: _controller.currentOperatorId == operator.id
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    _controller.setOperator(operator.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  /// 处理意图点击
  Future<void> _handleIntent(UserIntent intent) async {
    try {
      await _controller.handleIntent(intent);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('处理意图失败: $e')));
    }
  }

  /// 获取按钮文本
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

  /// 获取按钮颜色
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

  /// 获取阶段信息
  PhaseInfo _getPhaseInfo(AssistantPhase phase) {
    String label = '空闲';
    double progress = 0.0;
    Color color = Colors.grey;

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
        label = '准备录音';
        progress = 0.375;
        color = Colors.orange;
        break;
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

    return PhaseInfo(label: label, progress: progress, color: color);
  }
}
