import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/models/message_response.dart';
import '../../../../core/api/models/favorite_create.dart';
import '../../../../core/api/models/contact_create.dart';
import '../../../../core/api/models/block_user_request.dart';
import '../../../../core/network/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../../../pages/pager/widgets/waveform_visualization_widget.dart';

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
  bool _isLoadingContact = false;
  bool _isLoadingBlock = false;

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

  Future<void> _addContact() async {
    if (_isLoadingContact) return;
    final msg = widget.message;
    final currentUser = AuthService().currentUser;
    final targetId = msg.senderBipupuId == currentUser?.bipupuId
        ? msg.receiverBipupuId
        : msg.senderBipupuId;

    setState(() => _isLoadingContact = true);
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.contacts.postApiContacts(
          body: ContactCreate(contactId: targetId),
        ),
        operationName: 'AddContact',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('contact_added'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('add_contact_failed'.tr(args: [e.toString()])),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingContact = false);
    }
  }

  Future<void> _blockUser() async {
    if (_isLoadingBlock) return;
    final msg = widget.message;
    final currentUser = AuthService().currentUser;
    final targetId = msg.senderBipupuId == currentUser?.bipupuId
        ? msg.receiverBipupuId
        : msg.senderBipupuId;

    setState(() => _isLoadingBlock = true);
    try {
      final apiClient = ApiClient.instance;
      await apiClient.execute(
        () => apiClient.api.blacklist.postApiBlocks(
          body: BlockUserRequest(bipupuId: targetId),
        ),
        operationName: 'BlockUser',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('user_blocked'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('block_failed'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingBlock = false);
    }
  }

  bool _isNumeric(String str) {
    // 检查是否为纯数字（不包含点号等特殊字符）
    // 000001 会被判定为用户（纯数字）
    // cosmic.fortune 会被判定为服务号（包含点号）
    return str.isNotEmpty && RegExp(r'^\d+$').hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final currentUser = AuthService().currentUser;
    final isSender = msg.senderBipupuId == currentUser?.bipupuId;
    final isServiceAccount = !_isNumeric(msg.senderBipupuId);

    final senderContact = _imService.contacts.firstWhere(
      (contact) => contact.bipupuId == msg.senderBipupuId,
      orElse: () => null,
    );
    final displayName =
        senderContact?.remark ??
        senderContact?.info?.nickname ??
        senderContact?.info?.username ??
        msg.senderBipupuId;

    // 根据是否为服务号选择不同的头像加载方式
    final avatarUrl = isServiceAccount
        ? '/api/service_accounts/${msg.senderBipupuId}/avatar'
        : senderContact?.info?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('message_detail_title'.tr()),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发送者信息卡片
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 发送者头部
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.push('/user/detail/${msg.senderBipupuId}');
                        },
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                            .substring(0, 1)
                                            .toUpperCase()
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
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.senderBipupuId,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(msg.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isSender && !isServiceAccount)
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined),
                          onPressed: _isLoadingContact ? null : _addContact,
                          tooltip: 'add_contact_button'.tr(),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 消息内容区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 音频波形可视化
                  if (msg.waveform != null && msg.waveform!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: WaveformVisualizationWidget(
                            waveformData: msg.waveform!,
                            width: double.infinity,
                            height: 120,
                            waveColor: Colors.blue,
                            backgroundColor: Colors.grey[50]!,
                            showGrid: true,
                            showLabels: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // 消息内容
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.content,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 操作按钮
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                        icon: Icon(
                          _isFavorited
                              ? Icons.favorite
                              : Icons.favorite_outline,
                        ),
                        label: Text(
                          _isFavorited
                              ? 'action_unfavorite'.tr()
                              : 'action_favorite'.tr(),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: msg.content));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('message_copied'.tr())),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: Text('copy_message'.tr()),
                      ),
                      if (!isSender && !isServiceAccount)
                        ElevatedButton.icon(
                          onPressed: _isLoadingBlock ? null : _blockUser,
                          icon: const Icon(Icons.block),
                          label: Text('block_user_button'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
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
