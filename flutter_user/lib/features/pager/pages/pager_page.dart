import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/common/paginated_response.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:flutter_user/models/message/message_request.dart';
import 'package:flutter_user/models/common/enums.dart';
import '../../../core/services/speech_recognition_service.dart';
import '../../common/widgets/app_button.dart';

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final ApiService _api = bipupuApi;

  StreamSubscription<String>? _speechSubscription;

  // Target Selection
  bool _isDirectInput = false;
  User? _selectedFriend;
  List<User> _friends = [];

  // Vibration Settings
  String _selectedVibration = 'SHORT';
  final Map<String, String> _vibrationPatterns = {
    'SHORT': '短促震动',
    'LONG': '长震动',
    'SOS': 'SOS 模式',
    'HEARTBEAT': '心跳模式',
    'RAPID': '快速连击',
  };

  bool _isSending = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _initSpeechService();
  }

  Future<void> _initSpeechService() async {
    // Initialize with existing buffer if any
    _textController.text = _speechService.currentText;

    // Listen for live updates
    _speechSubscription = _speechService.onResult.listen((text) {
      if (mounted) {
        setState(() {
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      }
    });

    try {
      await _speechService.init();
      // Don't start recording automatically, wait for user action
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
    }
  }

  Future<void> _toggleListening() async {
    try {
      if (_isListening) {
        await _speechService.stop();
      } else {
        await _speechService.startRecording();
      }
      setState(() => _isListening = !_isListening);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('语音服务错误: $e')));
      }
    }
  }

  Future<void> _loadFriends() async {
    try {
      final response = await _api.adminGetUsers(page: 1, size: 100);
      setState(() {
        _friends = response
            .map((item) => User.fromJson(item.toJson()))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入发送内容')));
      return;
    }

    setState(() => _isSending = true);

    try {
      int? receiverId;

      if (_isDirectInput) {
        final username = _usernameController.text.trim();
        if (username.isEmpty) {
          throw Exception('请输入对方用户名');
        }
        // Search for user
        final users = await _searchUsers(username);
        // Find exact match preferred
        final exactMatch = users.items.firstWhere(
          (u) => u.username == username,
          orElse: () => users.items.isNotEmpty
              ? users.items.first
              : throw Exception('找不到该用户'),
        );
        receiverId = exactMatch.id;
      } else {
        if (_selectedFriend == null) {
          throw Exception('请选择一位好友');
        }
        receiverId = _selectedFriend!.id;
      }

      final pattern = {'vibration': _selectedVibration};

      final request = MessageCreateRequest(
        title: '寻呼消息',
        content: text,
        messageType: MessageType.device,
        priority: 1,
        pattern: pattern,
        receiverId: receiverId,
      );

      await _api.sendMessage(request);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('寻呼消息已发送！')));
      }

      _textController.clear();
      _speechService.clearBuffer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<PaginatedResponse<User>> _searchUsers(String query) async {
    final response = await _api.adminGetUsers(page: 1, size: 50);
    // Filter results by query locally since search parameter doesn't exist
    final filteredUsers = response
        .where(
          (user) =>
              user.username.toLowerCase().contains(query.toLowerCase()) ||
              (user.nickname?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();

    return PaginatedResponse<User>(
      items: filteredUsers.map((item) => User.fromJson(item.toJson())).toList(),
      total: filteredUsers.length,
      page: 1,
      size: filteredUsers.length,
      pages: 1,
    );
  }

  void _showFriendSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '选择好友',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _friends.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "暂无好友",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _friends.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                friend.username[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              friend.nickname ?? friend.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              friend.username,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() => _selectedFriend = friend);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('蓝牙传呼'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFriendSelector(),
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: '选择好友',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '发送目标',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: _isDirectInput,
                            onChanged: (val) =>
                                setState(() => _isDirectInput = val!),
                          ),
                          const Text('选择好友'),
                          const SizedBox(width: 20),
                          Radio<bool>(
                            value: true,
                            groupValue: _isDirectInput,
                            onChanged: (val) =>
                                setState(() => _isDirectInput = val!),
                          ),
                          const Text('直接输入'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isDirectInput)
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            border: OutlineInputBorder(),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _showFriendSelector,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedFriend?.nickname ??
                                        _selectedFriend?.username ??
                                        '点击选择好友',
                                    style: TextStyle(
                                      color: _selectedFriend != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.6,
                                            ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Message Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '传呼内容',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_textController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_textController.text.length} 字',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        onChanged: (v) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '键入内容或使用语音输入',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Voice Control
                      Center(child: _buildVoiceButton()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vibration Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '震动设置',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '震动脉冲',
                          prefixIcon: Icon(Icons.vibration, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedVibration,
                        items: _vibrationPatterns.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedVibration = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Send Button
              AppButton(
                text: '发送传呼',
                onPressed: _textController.text.trim().isNotEmpty && !_isSending
                    ? _sendMessage
                    : null,
                isLoading: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPressStart: (_) => _toggleListening(),
      onLongPressEnd: (_) => _toggleListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _isListening
              ? colorScheme.primary
              : colorScheme.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Icon(
          _isListening ? Icons.graphic_eq : Icons.mic,
          color: _isListening
              ? colorScheme.onPrimary
              : colorScheme.onPrimaryContainer,
          size: 40,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _speechService.stop();
    _textController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
