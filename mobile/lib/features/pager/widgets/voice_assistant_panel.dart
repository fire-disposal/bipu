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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _assistant.phase,
      builder: (context, value, child) {
        final AssistantPhase phase = value as AssistantPhase;
        final op =
            _config.getOperator(_assistant.currentOperatorId) ??
            _config.getOperator('op_system')!;
        final recipient = _assistant.currentRecipientId ?? '-';
        final preview = _assistant.currentText ?? '-';

        String phaseLabel;
        int phaseIndex;
        switch (phase) {
          case AssistantPhase.greeting:
            phaseLabel = '初始化引导';
            phaseIndex = 0;
            break;
          case AssistantPhase.askRecipientId:
            phaseLabel = '请提供收信方ID';
            phaseIndex = 1;
            break;
          case AssistantPhase.confirmRecipientId:
            phaseLabel = '请确认收信方ID';
            phaseIndex = 2;
            break;
          case AssistantPhase.guideRecordMessage:
          case AssistantPhase.recording:
            phaseLabel = '正在录音';
            phaseIndex = 3;
            break;
          case AssistantPhase.transcribing:
            phaseLabel = '转写中';
            phaseIndex = 4;
            break;
          case AssistantPhase.confirmMessage:
            phaseLabel = '请确认消息';
            phaseIndex = 5;
            break;
          case AssistantPhase.sending:
            phaseLabel = '发送中';
            phaseIndex = 6;
            break;
          case AssistantPhase.sent:
            phaseLabel = '已发送';
            phaseIndex = 7;
            break;
          case AssistantPhase.farewell:
            phaseLabel = '结束';
            phaseIndex = 8;
            break;
          case AssistantPhase.error:
            phaseLabel = '出错';
            phaseIndex = 8;
            break;
          case AssistantPhase.idle:
          default:
            phaseLabel = '空闲';
            phaseIndex = 0;
        }

        final total = 8;
        final progress = (phaseIndex / (total - 1)).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '语音助手：$phaseLabel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '目标：$recipient  •  预览：$preview',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: op.themeColor.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(op.themeColor),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '选择接线员',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OperatorGallery()),
                    );
                    setState(() {});
                  },
                  icon: Icon(Icons.grid_view, color: op.themeColor),
                ),
                ElevatedButton(
                  onPressed: (_assistant.state.value == AssistantState.idle)
                      ? () => _assistant.startListening()
                      : (_assistant.state.value == AssistantState.listening)
                      ? () => _assistant.stopListening()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_assistant.state.value == AssistantState.listening)
                        ? Colors.redAccent
                        : op.themeColor,
                  ),
                  child: Text(
                    _assistant.state.value == AssistantState.listening
                        ? '停止'
                        : '启动',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
