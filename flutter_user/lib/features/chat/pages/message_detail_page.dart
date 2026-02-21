import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../models/message/message_response.dart';
import '../../pager/widgets/waveform_widget.dart';

class MessageDetailPage extends StatefulWidget {
  final MessageResponse message;

  const MessageDetailPage({super.key, required this.message});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final ImService _imService = ImService();
  final AuthService _authService = AuthService();
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  /// 格式化 pattern 为字符串
  String _formatPattern(Map<String, dynamic> pattern) {
    try {
      if (pattern.containsKey('name')) {
        return pattern['name'].toString();
      } else if (pattern.containsKey('type')) {
        return pattern['type'].toString();
      } else {
        return pattern.toString();
      }
    } catch (_) {
      return 'Pattern';
    }
  }

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
    try {
      // 从API获取收藏列表，检查当前消息是否已收藏
      final favorites = await _imService.messageApi.getFavorites(
        page: 1,
        size: 100,
      );
      final isFavorited = favorites.items.any(
        (fav) => fav.message?.id == widget.message.id,
      );

      setState(() {
        _isFavorite = isFavorited;
      });
    } catch (e) {
      // 如果获取失败，默认显示未收藏状态
      debugPrint('检查收藏状态失败: $e');
      setState(() {
        _isFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() => _isLoadingFavorite = true);

    try {
      if (_isFavorite) {
        await _imService.messageApi.removeFavorite(widget.message.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('unfavorited'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
        setState(() => _isFavorite = false);
      } else {
        await _imService.messageApi.addFavorite(widget.message.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('favorited'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
        setState(() => _isFavorite = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('operation_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('copied_to_clipboard'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewSenderProfile() {
    final targetId = widget.message.senderBipupuId.isNotEmpty
        ? widget.message.senderBipupuId
        : widget.message.receiverBipupuId;
    context.push('/user/detail/$targetId');
  }

  Widget _buildMessageHeader() {
    final msg = widget.message;
    final currentUser = _authService.currentUser;
    final isMe = currentUser?.bipupuId == msg.senderBipupuId;

    final senderContact = _imService.getContact(msg.senderBipupuId);
    final displayName =
        senderContact?.remark ??
        senderContact?.info?.nickname ??
        senderContact?.info?.username ??
        msg.senderBipupuId;
    final avatarUrl = senderContact?.info?.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _viewSenderProfile,
            child: CircleAvatar(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                            : Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isMe ? 'me'.tr() : 'others'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${'to'.tr()}: ${msg.receiverBipupuId}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(msg.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    final msg = widget.message;
    final hasWaveform =
        msg.contentJson != null && msg.contentJson!['waveform_b64'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 消息内容
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'message_content'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  msg.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // 波形图（如果有）
          if (hasWaveform) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'voice_waveform'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (msg.contentJson != null &&
                      msg.contentJson!['waveform_b64'] != null)
                    StaticWaveform(
                      waveformBase64:
                          msg.contentJson!['waveform_b64'] as String,
                      height: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],

          // 消息模式（如果有）
          if (msg.pattern != null && msg.pattern!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pattern,
                    size: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatPattern(msg.pattern!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            label: _isFavorite ? 'unfavorite'.tr() : 'favorite'.tr(),
            color: _isFavorite
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
            onTap: _toggleFavorite,
            isLoading: _isLoadingFavorite,
          ),
          _buildActionButton(
            icon: Icons.content_copy,
            label: 'copy'.tr(),
            color: Theme.of(context).colorScheme.secondary,
            onTap: _copyToClipboard,
          ),
          _buildActionButton(
            icon: Icons.person,
            label: 'view_profile'.tr(),
            color: Theme.of(context).colorScheme.tertiary,
            onTap: _viewSenderProfile,
          ),
          _buildActionButton(
            icon: Icons.reply,
            label: 'reply'.tr(),
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              // TODO: 实现回复功能
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('reply_feature_coming_soon'.tr())),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(icon, color: color),
                  onPressed: onTap,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInfo() {
    final msg = widget.message;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'message_info'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.message,
            label: 'message_type'.tr(),
            value: msg.msgType,
          ),
          _buildInfoRow(
            icon: Icons.format_quote,
            label: 'content_length'.tr(),
            value: '${msg.content.length} ${'characters'.tr()}',
          ),
          _buildInfoRow(
            icon: Icons.info,
            label: 'message_id'.tr(),
            value: msg.id.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'message_detail'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 实现分享功能
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('share_feature_coming_soon'.tr())),
              );
            },
            tooltip: 'share'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息头部信息
            _buildMessageHeader(),

            const SizedBox(height: 20),

            // 消息内容
            _buildMessageContent(),

            const SizedBox(height: 24),

            // 操作按钮
            _buildActionButtons(),

            const SizedBox(height: 24),

            // 消息详细信息
            _buildMessageInfo(),

            const SizedBox(height: 32),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'message_detail_tip'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
