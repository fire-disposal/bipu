import 'package:flutter/material.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/api/models/message_response.dart';
import '../../../../core/api/models/message_create.dart';
import '../../../../core/api/models/message_type.dart';
import '../../../../core/api/models/favorite_create.dart';
import '../../../../core/network/api_client.dart';
import '../../../../pages/pager/widgets/waveform_visualization_widget.dart';

import 'package:easy_localization/easy_localization.dart';

class MessageConversationPage extends StatefulWidget {
  final String peerId;

  const MessageConversationPage({super.key, required this.peerId});

  @override
  State<MessageConversationPage> createState() =>
      _MessageConversationPageState();
}

class _MessageConversationPageState extends State<MessageConversationPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.messages.postApiMessages(
          body: MessageCreate(
            receiverId: widget.peerId,
            content: text,
            messageType: MessageType.normal,
          ),
        ),
        operationName: 'SendMessage',
      );
      _imService.refresh(); // Trigger immediate fetch
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send_failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _addToFavorite(MessageResponse msg) async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.messages.postApiMessagesMessageIdFavorite(
          messageId: msg.id,
          body: FavoriteCreate(note: ''),
        ),
        operationName: 'AddFavorite',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('favorited'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('favorite_failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter messages for this conversation
    final allMessages = _imService.messages;
    final conversation = allMessages
        .where(
          (m) => m.senderId == widget.peerId || m.receiverId == widget.peerId,
        )
        .toList();

    final currentUser = _authService.currentUser;
    final myId = currentUser?.bipupuId ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.peerId)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: conversation.length,
              itemBuilder: (context, index) {
                final msg = conversation[index];
                final isMe = msg.senderId == myId;

                return GestureDetector(
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.favorite),
                            title: Text('favorite'.tr()),
                            onTap: () {
                              Navigator.pop(context);
                              _addToFavorite(msg);
                            },
                          ),
                          if (isMe)
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: Text('delete_not_supported'.tr()),
                              enabled: false,
                            ),
                        ],
                      ),
                    );
                  },
                  child: Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.content),
                          if (msg.waveform != null && msg.waveform!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                WaveformVisualizationWidget(
                                  waveformData: msg.waveform!,
                                  height: 64,
                                  showGrid: false,
                                  showLabels: false,
                                ),
                              ],
                            ),
                          if (msg.pattern != null)
                            Text(
                              '${msg.pattern}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
