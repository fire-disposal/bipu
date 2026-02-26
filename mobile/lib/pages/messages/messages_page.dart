import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
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
  final AuthService _authService = AuthService();
  MessageFilter _selectedFilter = MessageFilter.received;
  List<MessageResponse> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.api.messages.getApiMessages();
      setState(() {
        _messages = response.messages;
      });
    } on ApiException catch (e) {
      debugPrint('Error loading messages: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() {
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Center(child: Text('please_login'.tr()));
    }

    final myId = currentUser.bipupuId;

    // Sort messages by latest first
    final List<MessageResponse> messages = List.from(_messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply filter selection
    final filtered = messages.where((msg) {
      switch (_selectedFilter) {
        case MessageFilter.received:
          return msg.receiverId == myId;
        case MessageFilter.sent:
          return msg.senderId == myId;
        case MessageFilter.subscription:
          // 服务号 / 订阅类消息在后端统一为 SYSTEM
          return msg.messageType.toString().toUpperCase().contains('SYSTEM');
        case MessageFilter.management:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('messages_title'.tr()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Four horizontal full-width menu bars
                _buildMenuBar(
                  'messages_menu_received'.tr(),
                  MessageFilter.received,
                ),
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
                            final title = msg.senderId == myId
                                ? 'To: ${msg.receiverId}'
                                : 'From: ${msg.senderId}';

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (msg.senderId.isNotEmpty
                                          ? msg.senderId
                                          : msg.receiverId)
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
                  _refresh();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: Text('management_clear_local'.tr()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _messages.clear());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: Text('management_delete_all_local'.tr()),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  setState(() => _messages.clear());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
