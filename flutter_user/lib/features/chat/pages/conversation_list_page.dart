import 'package:flutter/material.dart';
import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/core/network/rest_client.dart';
import 'package:flutter_core/models/message_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/auth_service.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage>
    with SingleTickerProviderStateMixin {
  final RestClient _api = bipupuApi;
  List<Message> _receivedMessages = [];
  List<Message> _sentMessages = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (AuthService().isGuest) return;

    setState(() => _isLoading = true);
    try {
      final responseReceived = await _api.getReceivedMessages(
        page: 1,
        size: 50,
      );

      setState(() {
        _receivedMessages = _groupMessages(responseReceived.items);
        _sentMessages = [];
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Message> _groupMessages(List<Message> messages) {
    final Map<int, Message> conversations = {};
    for (var msg in messages) {
      if (!conversations.containsKey(msg.senderId)) {
        conversations[msg.senderId] = msg;
      }
    }
    return conversations.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService().isGuest) {
      return _buildGuestView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(_receivedMessages, isReceived: true),
          _buildMessageList(_sentMessages, isReceived: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/contacts');
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages, {required bool isReceived}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceived ? Icons.inbox : Icons.send,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text('No ${isReceived ? 'received' : 'sent'} messages'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(message.senderId.toString().substring(0, 1)),
          ),
          title: Text('User ${message.senderId}'),
          subtitle: Text(
            message.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            DateFormat('MM/dd HH:mm').format(message.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () {
            context.push('/chat/${message.senderId}');
          },
        );
      },
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages (Guest)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Guest Mode - Online Chat Unavailable'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/bluetooth'),
              child: const Text('Go to Bluetooth Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
