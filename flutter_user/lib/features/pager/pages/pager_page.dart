import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/common/paginated_response.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:flutter_user/models/message/message_request.dart';
import 'package:flutter_user/models/common/enums.dart';
import '../../../services/speech_recognition_service.dart';
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

  // Attachments
  final Color _selectedColor = Colors.blue;
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
        ).showSnackBar(const SnackBar(content: Text('传呼成功')));
        _textController.clear();
        _speechService.clearBuffer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失�? $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<PaginatedResponse<User>> _searchUsers(String keyword) async {
    // 暂时使用 adminGetUsers，注意这可能需要管理员权限
    // 后续建议增加专门的公开搜索接口
    final response = await _api.adminGetUsers(page: 1, size: 20);
    return PaginatedResponse<User>(
      items: response.map((e) => User.fromJson(e.toJson())).toList(),
      total: response.length,
      page: 1,
      size: 20,
      pages: 1,
    );
  }

  @override
  void dispose() {
    _speechService.stop();
    _speechSubscription?.cancel();
    _textController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showFriendPicker() {
    showModalBottomSheet(
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final themeColor = _selectedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColor.withValues(alpha: 0.1),
              isDark ? Colors.black : Colors.white,
              themeColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '传呼中心',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Icon(
                        Icons.sensors,
                        size: 150,
                        color: themeColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.cleaning_services_outlined),
                  tooltip: '清空内容',
                  onPressed: () {
                    _speechService.clearBuffer();
                    _textController.clear();
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Target Selection
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.near_me,
                                    color: themeColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '发送至',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('选择好友'),
                                  icon: Icon(Icons.people_outline),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('直接输入'),
                                  icon: Icon(Icons.edit_note),
                                ),
                              ],
                              selected: {_isDirectInput},
                              onSelectionChanged: (Set<bool> selection) {
                                setState(() {
                                  _isDirectInput = selection.first;
                                  _selectedFriend = null;
                                  _usernameController.clear();
                                });
                              },
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                selectedBackgroundColor: themeColor.withValues(
                                  alpha: 0.2,
                                ),
                                selectedForegroundColor: themeColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (!_isDirectInput)
                              InkWell(
                                onTap: _showFriendPicker,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color: themeColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedFriend != null
                                              ? (_selectedFriend!.nickname ??
                                                    _selectedFriend!.username)
                                              : '点击选择好友...',
                                          style: TextStyle(
                                            color: _selectedFriend == null
                                                ? Colors.grey.shade600
                                                : null,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: '输入目标用户名',
                                  prefixIcon: Icon(
                                    Icons.person_search_outlined,
                                    color: themeColor,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Message Body
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '传呼消息',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                                      color: themeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_textController.text.length} 字',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: themeColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _textController,
                              maxLines: 4,
                              onChanged: (v) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '键入内容或使用下方语�?..',
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                filled: true,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // Voice Control
                            Center(child: _buildVoiceButton()),

                            const SizedBox(height: 24),

                            // Style settings
                            ExpansionTile(
                              title: const Text(
                                '传呼样式设置',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              leading: Icon(
                                Icons.tune,
                                size: 20,
                                color: themeColor,
                              ),
                              children: [_buildStyleSettings()],
                            ),

                            const SizedBox(height: 16),
                            AppButton(
                              text: _isSending ? '信号传输�?..' : '启动传呼',
                              onPressed: _isSending ? null : _sendMessage,
                              isLoading: _isSending,
                              icon: Icons.bolt,
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    final themeColor = _selectedColor;
    return GestureDetector(
      onLongPressStart: (_) => _toggleListening(),
      onLongPressEnd: (_) => _toggleListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _isListening ? themeColor : themeColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Icon(
          _isListening ? Icons.graphic_eq : Icons.mic,
          color: _isListening ? Colors.white : themeColor,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildStyleSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RGB颜色选择已禁用
          /*
          const Text(
            '信号灯颜色',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildColorSlider(
                      'R',
                      (_selectedColor.r * 255.0).round().clamp(0, 255),
                      Colors.red,
                      (v) => setState(
                        () =>
                            _selectedColor = _selectedColor.withRed(v.toInt()),
                      ),
                    ),
                    _buildColorSlider(
                      'G',
                      (_selectedColor.g * 255.0).round().clamp(0, 255),
                      Colors.green,
                      (v) => setState(
                        () => _selectedColor = _selectedColor.withGreen(
                          v.toInt(),
                        ),
                      ),
                    ),
                    _buildColorSlider(
                      'B',
                      (_selectedColor.b * 255.0).round().clamp(0, 255),
                      Colors.blue,
                      (v) => setState(
                        () =>
                            _selectedColor = _selectedColor.withBlue(v.toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          */
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '震动脉冲',
              prefixIcon: Icon(Icons.vibration, size: 20),
            ),
            value: _selectedVibration,
            items: _vibrationPatterns.entries.map((e) {
              return DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedVibration = val);
            },
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildColorSlider(
    String label,
    int value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: color,
            thumbColor: color,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  */
}
