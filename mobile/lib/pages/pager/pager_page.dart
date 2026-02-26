import 'package:flutter/material.dart';

enum PagerMode { voice, direct }

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  PagerMode _mode = PagerMode.voice;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatEntry> _messages = [];
  bool _drawerOpen = false;
  bool _isSending = false;

  @override
  void dispose() {
    _idController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _toggleMode() => setState(
    () => _mode = _mode == PagerMode.voice ? PagerMode.direct : PagerMode.voice,
  );

  void _forceSend() {
    final id = _idController.text.trim();
    final text = _messageController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写目标ID')));
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息内容不能为空')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    _messages.insert(0, _ChatEntry(false, text));
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _drawerOpen = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已强制发送')));
    });
  }

  void _sendDirect() {
    final id = _idController.text.trim();
    final text = _messageController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写目标ID')));
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息内容不能为空')));
      return;
    }

    setState(() {
      _messages.insert(0, _ChatEntry(false, text));
      _messageController.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('消息已发送')));
  }

  Widget _buildVoiceMode(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '传呼消息',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: '目标ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '消息内容',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        return Align(
                          alignment: m.fromOperator
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: m.fromOperator
                                  ? Colors.grey.shade200
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                color: m.fromOperator
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _drawerOpen = !_drawerOpen),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _drawerOpen
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: _drawerOpen ? 92 : 0,
                    child: _drawerOpen
                        ? Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size(200, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: _isSending ? null : _forceSend,
                              child: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      '强制发送',
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: '目标ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                labelText: '发送内容',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _sendDirect,
                  child: const Text('发送'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('传呼'),
        actions: [
          IconButton(
            tooltip: _mode == PagerMode.voice ? '切换到直接发送' : '切换到语音交互',
            icon: Icon(_mode == PagerMode.voice ? Icons.send : Icons.mic),
            onPressed: _toggleMode,
          ),
          const SizedBox(width: 6),
          const SizedBox(width: 8),
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
  final bool fromOperator; // true = operator (left), false = user (right)
  final String text;
  _ChatEntry(this.fromOperator, this.text);
}
