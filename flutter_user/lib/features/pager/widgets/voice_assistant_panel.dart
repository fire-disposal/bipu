import 'package:flutter/material.dart';
import 'package:flutter_user/features/assistant/assistant_controller.dart';
import 'package:flutter_user/features/assistant/assistant_config.dart';
// VoiceGuideService removed — AssistantController used directly
import 'operator_gallery.dart';

class VoiceAssistantPanel extends StatefulWidget {
  const VoiceAssistantPanel({super.key});

  @override
  State<VoiceAssistantPanel> createState() => _VoiceAssistantPanelState();
}

class _VoiceAssistantPanelState extends State<VoiceAssistantPanel> {
  final AssistantController _assistant = AssistantController();
  final AssistantConfig _config = AssistantConfig();

  @override
  void initState() {
    super.initState();
    _assistant.state.addListener(_onAssistantUpdate);
  }

  void _onAssistantUpdate() => setState(() {});

  @override
  void dispose() {
    _assistant.state.removeListener(_onAssistantUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _assistant.state.value;
    final isActive = state != AssistantState.idle;
    final op =
        _config.getOperator(_assistant.currentOperatorId) ??
        _config.getOperator('op_system')!; // 使用默认操作员
    final recipient = _assistant.currentRecipientId ?? '-';
    final preview = _assistant.currentText ?? '-';

    String stateLabel;
    switch (state) {
      case AssistantState.listening:
        stateLabel = '录音中';
        break;
      case AssistantState.thinking:
        stateLabel = '处理中';
        break;
      case AssistantState.speaking:
        stateLabel = '播放中';
        break;
      case AssistantState.idle:
      default:
        stateLabel = '空闲';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Operator badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: op.themeColor.withOpacity(0.08),
              ),
              alignment: Alignment.center,
              child: Text(
                op.name.isNotEmpty ? op.name[0] : 'O',
                style: TextStyle(
                  color: op.themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '语音助手：$stateLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '目标：$recipient  •  预览：$preview',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Open operator gallery
            IconButton(
              tooltip: '选择接线员',
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => OperatorGallery()));
                setState(() {});
              },
              icon: Icon(Icons.grid_view, color: op.themeColor),
            ),

            // Start/Stop (only allow start when idle, stop when listening)
            ElevatedButton(
              onPressed: (state == AssistantState.idle)
                  ? () => _assistant.startListening()
                  : (state == AssistantState.listening)
                  ? () => _assistant.stopListening()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (state == AssistantState.listening)
                    ? Colors.redAccent
                    : op.themeColor,
              ),
              child: Text(state == AssistantState.listening ? '停止' : '启动'),
            ),
          ],
        ),
      ),
    );
  }
}
