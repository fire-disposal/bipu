import 'package:flutter/material.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../models/message/message_response.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../pager/widgets/waveform_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String peerId;

  const ChatPage({super.key, required this.peerId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
      await _imService.messageApi.sendMessage(
        receiverId: widget.peerId,
        content: text,
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
      await _imService.messageApi.addFavorite(msg.id);
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
          (m) =>
              m.senderBipupuId == widget.peerId ||
              m.receiverBipupuId == widget.peerId,
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
                final isMe = msg.senderBipupuId == myId;

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
                          if (msg.contentJson != null &&
                              msg.contentJson!['waveform_b64'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                StaticWaveform(
                                  waveformBase64:
                                      msg.contentJson!['waveform_b64'],
                                  height: 64,
                                  color: isMe ? Colors.blue : Colors.green,
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        try {
                                          final pngBytes =
                                              await exportWaveformPng(
                                                msg.contentJson!['waveform_b64'],
                                              );
                                          final tmp =
                                              await getTemporaryDirectory();
                                          final file = File(
                                            '${tmp.path}/waveform_${msg.id}.png',
                                          );
                                          await file.writeAsBytes(pngBytes);
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '已导出声纹：${file.path}',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('导出失败：$e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.download),
                                      label: const Text('导出声纹'),
                                    ),
                                  ],
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
                      hintText: '������Ϣ...',
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
