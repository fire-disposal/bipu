import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/models/message_response.dart';
import '../../../../core/api/models/favorite_create.dart';
import '../../../../core/network/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../../../pages/pager/widgets/waveform_widget.dart';

class MessageDetailPage extends StatefulWidget {
  final MessageResponse message;

  const MessageDetailPage({super.key, required this.message});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final ImService _imService = ImService();
  bool _isFavorited = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _imService.addListener(_onImChanged);
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _imService.removeListener(_onImChanged);
    super.dispose();
  }

  void _onImChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkFavoriteStatus() async {
    // 检查消息是否已收藏
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.execute(
        () => apiClient.api.messages.getApiMessagesFavorites(
          page: 1,
          pageSize: 100,
        ),
        operationName: 'GetFavorites',
      );

      if (mounted) {
        setState(() {
          _isFavorited = response.favorites.any(
            (fav) => fav.messageId == widget.message.id,
          );
        });
      }
    } catch (e) {
      debugPrint('检查收藏状态失败: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() => _isLoadingFavorite = true);
    try {
      final apiClient = ApiClient.instance;

      if (_isFavorited) {
        // 取消收藏
        await apiClient.execute(
          () => apiClient.api.messages.deleteApiMessagesMessageIdFavorite(
            messageId: widget.message.id,
          ),
          operationName: 'RemoveFavorite',
        );
        if (mounted) {
          setState(() => _isFavorited = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('unfavorited'.tr())));
        }
      } else {
        // 添加收藏
        await apiClient.execute(
          () => apiClient.api.messages.postApiMessagesMessageIdFavorite(
            messageId: widget.message.id,
            body: FavoriteCreate(note: ''),
          ),
          operationName: 'AddFavorite',
        );
        if (mounted) {
          setState(() => _isFavorited = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('favorited'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited ? 'unfavorite_failed'.tr() : 'favorite_failed'.tr(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final currentUser = AuthService().currentUser;

    final senderContact = _imService.contacts.firstWhere(
      (contact) => contact.bipupuId == msg.senderId,
      orElse: () => null,
    );
    final displayName =
        senderContact?.remark ??
        senderContact?.info?.nickname ??
        senderContact?.info?.username ??
        msg.senderId;
    final avatarUrl = senderContact?.info?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('message_detail_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Open sender detail page
              final targetId = msg.senderId.isNotEmpty
                  ? msg.senderId
                  : msg.receiverId;
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
                'From: ${msg.senderId}  →  To: ${msg.receiverId}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              if (msg.waveform != null && msg.waveform!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    StaticWaveform(
                      waveformBase64: msg.waveform!.join(','),
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
                    onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_outline,
                    ),
                    label: Text(
                      _isFavorited
                          ? 'action_unfavorite'.tr()
                          : 'action_favorite'.tr(),
                    ),
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
