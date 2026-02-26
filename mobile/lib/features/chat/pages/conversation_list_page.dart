import 'package:flutter/material.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/services/auth_service.dart';

enum MessageFilter { received, sent, subscription, management }

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ImService _imService = ImService();
  final AuthService _authService = AuthService();
  MessageFilter _selectedFilter = MessageFilter.received;

  @override
  void initState() {
    super.initState();
    _imService.addListener(_refresh);
  }

  @override
  void dispose() {
    _imService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _getPeerId(MessageResponse msg, String myId) {
    return msg.senderBipupuId == myId
        ? msg.receiverBipupuId
        : msg.senderBipupuId;
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
          // 服务号 / 订阅类消息在后端统一为 SYSTEM
          return msg.msgType.toUpperCase() == 'SYSTEM';
        case MessageFilter.management:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('messages_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _imService.refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Socket connection status (simple indicator)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ValueListenableBuilder<bool>(
              valueListenable: _imService.socketConnected,
              builder: (context, connected, _) {
                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: connected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected ? '系统Socket：已连接' : '系统Socket：未连接',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          // Four horizontal full-width menu bars
          _buildMenuBar('messages_menu_received'.tr(), MessageFilter.received),
          _buildMenuBar('messages_menu_sent'.tr(), MessageFilter.sent),
          _buildMenuBar(
            'messages_menu_subscription'.tr(),
            MessageFilter.subscription,
          ),
          _buildMenuBar(
            'messages_menu_management'.tr(),
            MessageFilter.management,
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('no_messages'.tr()))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final msg = filtered[index];
                      final title = msg.senderBipupuId == myId
                          ? 'To: ${msg.receiverBipupuId}'
                          : 'From: ${msg.senderBipupuId}';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (msg.senderBipupuId.isNotEmpty
                                    ? msg.senderBipupuId
                                    : msg.receiverBipupuId)
                                .substring(0, 1)
                                .toUpperCase(),
                          ),
                        ),
                        title: Text(title),
                        subtitle: Text(
                          msg.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          DateFormat('MM-dd HH:mm').format(msg.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          context.push('/messages/detail', extra: msg);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBar(String title, MessageFilter filter) {
    final selected = _selectedFilter == filter;
    return Material(
      color: selected ? Theme.of(context).primaryColor.withOpacity(0.08) : null,
      child: InkWell(
        onTap: () {
          if (filter == MessageFilter.management) {
            _showManagementSheet();
          } else {
            setState(() {
              _selectedFilter = filter;
            });
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16)),
              if (selected)
                const Icon(Icons.check, size: 18, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text('management_refresh'.tr()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _imService.refresh();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: Text('management_clear_local'.tr()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _imService.clearLocalCache();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: Text('management_delete_all_local'.tr()),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  // As a simple/temporary action: clear local cache
                  _imService.clearLocalCache();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
