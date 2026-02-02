import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/core/network/rest_client.dart';
import 'package:flutter_core/models/paginated_response.dart';
import 'package:flutter_core/models/user_model.dart';
import '../../../services/speech_recognition_service.dart';

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final RestClient _api = bipupuApi;

  StreamSubscription<String>? _speechSubscription;

  // Target Selection
  bool _isDirectInput = false;
  User? _selectedFriend;
  List<User> _friends = [];
  bool _isLoadingFriends = false;

  // Attachments
  Color _selectedColor = Colors.blue;
  String _selectedVibration = 'SHORT';
  final Map<String, String> _vibrationPatterns = {
    'SHORT': 'Short Buzz',
    'LONG': 'Long Buzz',
    'SOS': 'SOS Pattern',
    'HEARTBEAT': 'Heartbeat',
    'RAPID': 'Rapid Fire',
  };

  bool _isSending = false;

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
      await _speechService.startRecording();
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);
    try {
      final response = await _api.getFriends(page: 1, size: 100);
      setState(() {
        _friends = response.items;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedVibration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message or select a pattern'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      int? receiverId;

      if (_isDirectInput) {
        final username = _usernameController.text.trim();
        if (username.isEmpty) {
          throw Exception('Please enter a username');
        }
        // Search for user
        final users = await _searchUsers(username);
        // Find exact match preferred
        final exactMatch = users.items.firstWhere(
          (u) => u.username == username,
          orElse: () => users.items.isNotEmpty
              ? users.items.first
              : throw Exception('User not found'),
        );
        receiverId = exactMatch.id;
      } else {
        if (_selectedFriend == null) {
          throw Exception('Please select a friend');
        }
        receiverId = _selectedFriend!.id;
      }

      final pattern = {
        'rgb':
            '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'vibration': _selectedVibration,
      };

      await _api.createMessage({
        'content': text,
        'receiver_id': receiverId,
        'message_type': 'device', // Using 'device' type for pager messages
        'priority': 1,
        'pattern': pattern,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!')),
        );
        _textController.clear();
        _speechService.clearBuffer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<PaginatedResponse<User>> _searchUsers(String keyword) {
    return _api.adminGetAllUsers(
      page: 1,
      size: 20,
      search: keyword.isNotEmpty ? keyword : null,
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

  void _showFriendSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                'Select Friend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _friends.isEmpty
                    ? const Center(child: Text("No friends found"))
                    : ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(friend.username[0].toUpperCase()),
                            ),
                            title: Text(friend.nickname ?? friend.username),
                            subtitle: Text(friend.username),
                            onTap: () {
                              setState(() {
                                _selectedFriend = friend;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pager Station'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clear Buffer',
            onPressed: () {
              _speechService.clearBuffer();
              _textController.clear();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Target Selection
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'To:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Direct'),
                            Switch(
                              value: !_isDirectInput,
                              onChanged: (val) {
                                setState(() {
                                  _isDirectInput = !val;
                                  _selectedFriend = null;
                                  _usernameController.clear();
                                });
                              },
                            ),
                            const Text('Friend'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (!_isDirectInput)
                      InkWell(
                        onTap: _showFriendSelector,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Select Friend',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _selectedFriend?.username ??
                                (_selectedFriend?.nickname ?? 'Select...'),
                            style: TextStyle(
                              color: _selectedFriend == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      )
                    else
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Attachments
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Icon(Icons.settings_remote),
                    SizedBox(width: 8),
                    Text('Device Settings (RGB & Vibrate)'),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RGB Color'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildColorSlider(
                                    'R',
                                    _selectedColor.red,
                                    Colors.red,
                                    (val) {
                                      setState(
                                        () => _selectedColor = _selectedColor
                                            .withRed(val.toInt()),
                                      );
                                    },
                                  ),
                                  _buildColorSlider(
                                    'G',
                                    _selectedColor.green,
                                    Colors.green,
                                    (val) {
                                      setState(
                                        () => _selectedColor = _selectedColor
                                            .withGreen(val.toInt()),
                                      );
                                    },
                                  ),
                                  _buildColorSlider(
                                    'B',
                                    _selectedColor.blue,
                                    Colors.blue,
                                    (val) {
                                      setState(
                                        () => _selectedColor = _selectedColor
                                            .withBlue(val.toInt()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Vibration Pattern',
                            prefixIcon: Icon(Icons.vibration),
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedVibration,
                          items: _vibrationPatterns.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedVibration = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Message Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Type or speak...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'SEND PAGE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSlider(
    String label,
    int value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 20,
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
}
