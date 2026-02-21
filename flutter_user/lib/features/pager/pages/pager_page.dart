import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bipupu/features/assistant/intent_driven_assistant_controller.dart';
import 'package:bipupu/features/assistant/assistant_config.dart';
import '../widgets/operator_gallery.dart';
import '../widgets/voice_assistant_panel.dart';

enum PagerMode { voice, direct }

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final IntentDrivenAssistantController _assistant =
      IntentDrivenAssistantController();
  final AssistantConfig _config = AssistantConfig();
  PagerMode _mode = PagerMode.voice;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatEntry> _messages = [];
  bool _isSending = false;
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _assistant.addListener(_onAssistantUpdate);
    _setupEventSubscription();
  }

  @override
  void dispose() {
    _assistant.removeListener(_onAssistantUpdate);
    _eventSub?.cancel();
    _idController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _setupEventSubscription() {
    // 监听语音命令中心的事件（暂时注释）
    // _eventSub = _assistant.voiceCommandCenter.onResult.listen((result) {
    //   if (result.isNotEmpty) {
    //     _handleVoiceResult(result);
    //   }
    // });
  }

  void _onAssistantUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onUserMessageSent(String text) {
    setState(() {
      _messages.add(
        _ChatEntry(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });
  }

  void _switchMode(PagerMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  Future<void> _sendDirectMessage() async {
    if (_idController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写收信方ID和消息内容')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // 使用意图驱动控制器发送消息
      await _assistant.handleIntent(
        UserIntent.send,
        params: {
          'recipientId': _idController.text,
          'text': _messageController.text,
        },
      );

      _onUserMessageSent(_messageController.text);
      _messageController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息发送成功')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('传呼机'),
        actions: [
          IconButton(
            icon: Icon(
              _mode == PagerMode.voice ? Icons.keyboard_voice : Icons.keyboard,
            ),
            onPressed: () => _switchMode(
              _mode == PagerMode.voice ? PagerMode.direct : PagerMode.voice,
            ),
            tooltip: _mode == PagerMode.voice ? '切换到文本模式' : '切换到语音模式',
          ),
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OperatorGallery()),
              );
              if (mounted) setState(() {});
            },
            tooltip: '选择操作员',
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息历史区域
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('暂无消息记录'))
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final entry = _messages[_messages.length - 1 - index];
                      return _ChatBubble(entry: entry);
                    },
                  ),
          ),

          // 语音助手面板或直接输入区域
          if (_mode == PagerMode.voice)
            VoiceAssistantPanel(
              assistant: _assistant,
              config: _config,
              onMessageSent: _onUserMessageSent,
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: '收信方ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '消息内容',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendDirectMessage,
                    child: _isSending
                        ? const CircularProgressIndicator()
                        : const Text('发送消息'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatEntry({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatEntry entry;

  const _ChatBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: entry.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.isUser
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: TextStyle(
                    color: entry.isUser ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: entry.isUser
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
