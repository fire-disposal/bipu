import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user/features/assistant/assistant_controller.dart';
import 'package:flutter_user/features/assistant/assistant_config.dart';
import '../widgets/operator_gallery.dart';
import '../widgets/voice_assistant_panel.dart';

enum PagerMode { voice, direct }

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final AssistantController _assistant = AssistantController();
  final AssistantConfig _config = AssistantConfig();
  PagerMode _mode = PagerMode.voice;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatEntry> _messages = [];
  bool _drawerOpen = false;
  bool _isSending = false;
  StreamSubscription? _eventSub;

  @override
  void dispose() {
    _assistant.removeListener(_onAssistantUpdate);
    _eventSub?.cancel();
    _idController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _assistant.addListener(_onAssistantUpdate);
    _eventSub = _assistant.onEvent.listen(_handleAssistantEvent);
    _initAssistant();
  }

  Future<void> _initAssistant() async {
    try {
      await _assistant.init();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('语音引擎初始化失败: $e')));
      }
    }
  }

  void _handleAssistantEvent(AssistantEvent event) {
    if (!mounted) return;

    // 处理操作员发出的文本（TTS 脚本或直接朗读）
    if (event.isOperator && event.text != null && event.text!.isNotEmpty) {
      setState(() {
        _messages.insert(0, _ChatEntry(true, event.text!));
      });
    }
  }

  void _onAssistantUpdate() {
    if (!mounted) return;

    // 同步助手状态到输入框
    if (_assistant.currentRecipientId != null &&
        _idController.text != _assistant.currentRecipientId) {
      _idController.text = _assistant.currentRecipientId!;
    }
    if (_assistant.currentText != null &&
        _messageController.text != _assistant.currentText) {
      _messageController.text = _assistant.currentText!;
    }

    // 监听发送成功事件（用户侧）
    if (_assistant.currentPhase == AssistantPhase.sent && !_isSending) {
      _onUserMessageSent(_assistant.currentText ?? "");
    }

    setState(() {});
  }

  void _onUserMessageSent(String text) {
    if (text.isEmpty) return;
    // 检查是否已经添加过（避免重复）
    if (_messages.isNotEmpty &&
        _messages.first.text == text &&
        !_messages.first.fromOperator) {
      return;
    }
    setState(() {
      _messages.insert(0, _ChatEntry(false, text));
    });
  }

  void _toggleMode() => setState(
    () => _mode = _mode == PagerMode.voice ? PagerMode.direct : PagerMode.voice,
  );

  void _forceSend() async {
    final id = _idController.text.trim();
    final text = _messageController.text.trim();
    if (id.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID和内容不能为空')));
      return;
    }

    setState(() => _isSending = true);
    try {
      _assistant.setRecipient(id);
      await _assistant.send();
      _onUserMessageSent(text);
      _messageController.clear();
      _drawerOpen = false;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendDirect() async {
    final id = _idController.text.trim();
    final text = _messageController.text.trim();
    if (id.isEmpty || text.isEmpty) return;

    _assistant.setRecipient(id);
    try {
      await _assistant.send();
      _onUserMessageSent(text);
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    }
  }

  Widget _buildVoiceMode(BuildContext context) {
    return Column(
      children: [
        const VoiceAssistantPanel(),
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: '目标ID',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _assistant.setRecipient(v),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '消息内容',
                          prefixIcon: Icon(Icons.message_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      return _buildChatBubble(m);
                    },
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(_ChatEntry m) {
    final isOp = m.fromOperator;
    return Align(
      alignment: isOp ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOp
              ? Colors.grey.shade200
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isOp ? 0 : 12),
            bottomRight: Radius.circular(isOp ? 12 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: isOp
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOp)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '接线员',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              m.text,
              style: TextStyle(color: isOp ? Colors.black87 : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _drawerOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
          ),
          onPressed: () => setState(() => _drawerOpen = !_drawerOpen),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _drawerOpen ? 80 : 0,
          child: _drawerOpen
              ? Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _forceSend,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('强制发送'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDirectMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: '目标ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                labelText: '发送内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _sendDirect,
              child: const Text('立即发送'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('传呼机'),
        actions: [
          IconButton(
            icon: Icon(_mode == PagerMode.voice ? Icons.keyboard : Icons.mic),
            onPressed: _toggleMode,
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const OperatorGallery())),
          ),
        ],
      ),
      body: SafeArea(
        child: _mode == PagerMode.voice
            ? _buildVoiceMode(context)
            : _buildDirectMode(context),
      ),
    );
  }
}

class _ChatEntry {
  final bool fromOperator;
  final String text;
  _ChatEntry(this.fromOperator, this.text);
}
