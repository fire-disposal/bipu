import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../../../models/message/message_response.dart';
import 'package:go_router/go_router.dart';
import '../../pager/widgets/waveform_widget.dart';

class MessageDetailPage extends StatefulWidget {
  final MessageResponse message;

  const MessageDetailPage({super.key, required this.message});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final ImService _imService = ImService();

  @override
  void initState() {
    super.initState();
    _imService.addListener(_onImChanged);
  }

  @override
  void dispose() {
    _imService.removeListener(_onImChanged);
    super.dispose();
  }

  void _onImChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final currentUser = AuthService().currentUser;
    final isMe = currentUser?.bipupuId == msg.senderBipupuId;

    final senderContact = _imService.getContact(msg.senderBipupuId);
    final displayName =
        senderContact?.remark ??
        senderContact?.info?.nickname ??
        senderContact?.info?.username ??
        msg.senderBipupuId;
    final avatarUrl = senderContact?.info?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('message_detail_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Open sender detail page
              final targetId = msg.senderBipupuId.isNotEmpty
                  ? msg.senderBipupuId
                  : msg.receiverBipupuId;
              context.push('/user/detail/$targetId');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From: ${msg.senderBipupuId}  →  To: ${msg.receiverBipupuId}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              if (msg.contentJson != null &&
                  msg.contentJson!['waveform_b64'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    StaticWaveform(
                      waveformBase64: msg.contentJson!['waveform_b64'],
                      height: 96,
                    ),
                  ],
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(msg.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(msg.content, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              if (msg.pattern != null)
                Text(
                  '${msg.pattern}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _imService.messageApi.addFavorite(msg.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('favorited'.tr())),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'favorite_failed'.tr(args: [e.toString()]),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.favorite),
                    label: Text('action_favorite'.tr()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // For now: copy message text
                      Clipboard.setData(ClipboardData(text: msg.content));
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('已复制')));
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: Text('action_copy'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
