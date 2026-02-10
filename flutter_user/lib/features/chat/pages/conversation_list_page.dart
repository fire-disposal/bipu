import 'package:flutter/material.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/services/auth_service.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final ImService _imService = ImService();
  final AuthService _authService = AuthService();

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

    // Group by conversation (peerId)
    final Map<String, MessageResponse> lastMessageMap = {};

    for (var msg in allMessages) {
      final peerId = _getPeerId(msg, myId);
      lastMessageMap[peerId] = msg;
    }

    final conversations = lastMessageMap.entries.toList();
    conversations.sort(
      (a, b) => b.value.createdAt.compareTo(a.value.createdAt),
    );

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
      body: conversations.isEmpty
          ? Center(child: Text('no_messages'.tr()))
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final entry = conversations[index];
                final peerId = entry.key;
                final lastMsg = entry.value;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      peerId.isNotEmpty
                          ? peerId.substring(0, 1).toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(peerId),
                  subtitle: Text(
                    lastMsg.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat('MM-dd HH:mm').format(lastMsg.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    context.push('/chat', extra: peerId);
                  },
                );
              },
            ),
    );
  }
}
