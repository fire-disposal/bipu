import 'package:flutter/material.dart';
import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/core/network/rest_client.dart';
import 'package:flutter_core/models/message_model.dart';
import 'send_system_message_page.dart';

class MessageManagementPage extends StatefulWidget {
  const MessageManagementPage({super.key});

  @override
  State<MessageManagementPage> createState() => _MessageManagementPageState();
}

class _MessageManagementPageState extends State<MessageManagementPage> {
  RestClient get _api => bipupuApi;
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
      final response = await _api.adminGetAllSystemNotifications(
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

  Future<void> _deleteMessage(int id) async {
    try {
      await _api.adminDeleteSystemNotification(id);
      _loadMessages(); // Reload the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
    }
  }

  Future<void> _showStats() async {
    try {
      final stats = await _api.adminGetSystemNotificationStats();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('System Notification Stats'),
          content: Text('Stats: $stats'), // You can format this better
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load stats: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: _showStats),
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
        tooltip: 'Send System Message',
        child: const Icon(Icons.campaign),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message.createdAt.toString()),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMessage(message.id),
                            ),
                          ],
                        ),
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
