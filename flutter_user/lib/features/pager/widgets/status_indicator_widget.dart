import 'package:flutter/material.dart';
import '../../../features/assistant/assistant_controller.dart';
import '../../../features/assistant/assistant_config.dart';
import 'waveform_controller.dart';

class StatusIndicatorWidget extends StatefulWidget {
  const StatusIndicatorWidget({super.key});

  @override
  State<StatusIndicatorWidget> createState() => _StatusIndicatorWidgetState();
}

class _StatusIndicatorWidgetState extends State<StatusIndicatorWidget> {
  final AssistantController _assistant = AssistantController();
  final AssistantConfig _config = AssistantConfig();
  late final WaveformController _waveformController;

  String _status = '空闲';
  Color _color = Colors.grey;
  IconData _icon = Icons.mic_off;

  @override
  void initState() {
    super.initState();
    _waveformController = WaveformController(
      _assistant,
    ); // 使用AssistantController
    _waveformController.addListener(_onWaveformUpdate);
    _assistant.state.addListener(_onAssistantStateUpdate); // 监听助手状态
    // 初始化时根据当前助手状态设置显示
    _updateStatusFromAssistant();
    _waveformController.start();
  }

  void _onAssistantStateUpdate() {
    _updateStatusFromAssistant();
  }

  void _updateStatusFromAssistant() {
    final state = _assistant.state.value;
    setState(() {
      switch (state) {
        case AssistantState.listening:
          _status = '语音识别中';
          _color = Colors.green;
          _icon = Icons.mic;
          break;
        case AssistantState.thinking:
          _status = '处理中';
          _color = Colors.orange;
          _icon = Icons.hourglass_top;
          break;
        case AssistantState.speaking:
          _status = '语音合成中';
          _color = Colors.blue;
          _icon = Icons.volume_up;
          break;
        case AssistantState.idle:
        default:
          _updateFromVoiceGuide();
          break;
      }
    });
  }

  void _onWaveformUpdate() {
    // 如果助手正在监听，优先显示助手状态
    if (_assistant.state.value == AssistantState.listening) {
      _updateStatusFromAssistant();
    } else if (_waveformController.amplitudes.isNotEmpty) {
      setState(() {
        _status = 'ASR 录音中';
        _color = Colors.green;
        _icon = Icons.mic;
      });
    } else {
      // Fallback to voice guide status
      _updateFromVoiceGuide();
    }
  }

  void _onPlaybackStatus(String status) {
    // Playback status handled via AssistantController state now; no-op
  }

  void _updateFromVoiceGuide() {
    // Fallback: reflect assistant idle state
    setState(() {
      _status = '空闲';
      _color = Colors.grey;
      _icon = Icons.mic_off;
    });
  }

  @override
  void dispose() {
    _assistant.state.removeListener(_onAssistantStateUpdate);
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 16),
          const SizedBox(width: 6),
          Text(
            _status,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
