import 'package:flutter/material.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/services/auth_service.dart';

enum MessageFilter { received, sent, subscription }

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ImService _imService = ImService();
  final AuthService _authService = AuthService();
  MessageFilter _selectedFilter = MessageFilter.received;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imService.addListener(_refresh);
    _loadMessages();
  }

  @override
  void dispose() {
    _imService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      await _imService.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('load_messages_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMessageTitle(MessageResponse msg, String myId) {
    if (msg.msgType.toUpperCase() == 'SYSTEM') {
      return 'system_message'.tr();
    } else if (msg.senderBipupuId == myId) {
      return 'sent_to'.tr(args: [msg.receiverBipupuId]);
    } else {
      return 'received_from'.tr(args: [msg.senderBipupuId]);
    }
  }

  String _getMessageSubtitle(MessageResponse msg) {
    final content = msg.content;
    if (content.length > 60) {
      return '${content.substring(0, 60)}...';
    }
    return content;
  }

  Widget _buildMessageCard(MessageResponse msg, String myId) {
    final isSystem = msg.msgType.toUpperCase() == 'SYSTEM';
    final isSent = msg.senderBipupuId == myId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSystem
                ? Colors.blue.withOpacity(0.1)
                : isSent
                ? Colors.green.withOpacity(0.1)
                : Colors.purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSystem
                ? Icons.notifications
                : isSent
                ? Icons.send
                : Icons.email,
            color: isSystem
                ? Colors.blue
                : isSent
                ? Colors.green
                : Colors.purple,
          ),
        ),
        title: Text(
          _getMessageTitle(msg, myId),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getMessageSubtitle(msg),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(msg.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.outline,
        ),
        onTap: () {
          context.push('/messages/detail', extra: msg);
        },
      ),
    );
  }

  Widget _buildFilterChip(MessageFilter filter) {
    final isSelected = _selectedFilter == filter;
    final label = filter == MessageFilter.received
        ? 'received'.tr()
        : filter == MessageFilter.sent
        ? 'sent'.tr()
        : 'subscription'.tr();

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = filter);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'no_messages'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == MessageFilter.received
                ? 'no_received_messages'.tr()
                : _selectedFilter == MessageFilter.sent
                ? 'no_sent_messages'.tr()
                : 'no_subscription_messages'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Center(child: Text('please_login'.tr()));
    }

    final myId = currentUser.bipupuId;
    final allMessages = _imService.messages;

    // Sort messages by latest first
    final List<MessageResponse> messages = List.from(allMessages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply filter selection
    final filtered = messages.where((msg) {
      switch (_selectedFilter) {
        case MessageFilter.received:
          return msg.receiverBipupuId == myId;
        case MessageFilter.sent:
          return msg.senderBipupuId == myId;
        case MessageFilter.subscription:
          return msg.msgType.toUpperCase() == 'SYSTEM';
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('messages'.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMessages,
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 过滤器选择
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip(MessageFilter.received),
                _buildFilterChip(MessageFilter.sent),
                _buildFilterChip(MessageFilter.subscription),
              ],
            ),
          ),
          const Divider(height: 1),
          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildMessageCard(filtered[index], myId),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
