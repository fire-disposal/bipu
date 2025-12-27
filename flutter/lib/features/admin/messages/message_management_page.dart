import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import '../../../repositories/message_repository.dart';
import 'send_system_message_page.dart';

class MessageManagementPage extends StatefulWidget {
  const MessageManagementPage({super.key});

  @override
  State<MessageManagementPage> createState() => _MessageManagementPageState();
}

class _MessageManagementPageState extends State<MessageManagementPage> {
  final MessageRepository _messageRepository = MessageRepository();
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _total = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _messageRepository.getMessages(
        page: _currentPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = response.items;
        _total = response.total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SendSystemMessagePage()),
          ).then((_) => _loadMessages());
        },
        child: const Icon(Icons.campaign),
        tooltip: 'Send System Message',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ListTile(
                        title: Text(message.title),
                        subtitle: Text(message.content),
                        trailing: Text(message.createdAt.toString()),
                      );
                    },
                  ),
                ),
                _buildPagination(),
              ],
            ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _pageSize).ceil();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadMessages();
                  }
                : null,
          ),
          Text('Page $_currentPage of $totalPages (Total: $_total)'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadMessages();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
