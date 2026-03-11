import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/models/message_response.dart';
import '../../../../core/api/models/contact_create.dart';
import '../../../../core/api/models/block_user_request.dart';
import '../../../../core/api/models/user_public.dart';
import '../../../../core/api/models/service_account_response.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/user_avatar.dart';
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

  // 发送者信息（异步加载）
  UserPublic? _senderUserInfo;
  ServiceAccountResponse? _senderServiceInfo;

  Color get _onSurfaceColor => Theme.of(context).colorScheme.onSurface;
  Color get _cardColor =>
      Theme.of(context).cardTheme.color ?? Colors.transparent;
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _dividerColor => Theme.of(context).dividerColor;
  Color get _iconColor => Theme.of(context).iconTheme.color ?? Colors.black;
  Color get _surfaceContainerHigh =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _surfaceContainerLow =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  @override
  void initState() {
    super.initState();
    _imService.addListener(_onImChanged);
    _checkFavoriteStatus();
    _loadSenderInfo();
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
      // 使用新的统一接口
      final response = await _imService.getFavorites(page: 1, pageSize: 100);

      if (mounted) {
        setState(() {
          _isFavorited = (response['favorites'] as List).any(
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
      if (_isFavorited) {
        // 取消收藏
        await _imService.removeFavorite(widget.message.id);
        if (mounted) {
          setState(() => _isFavorited = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('unfavorited'.tr())));
        }
      } else {
        // 添加收藏
        await _imService.addFavorite(widget.message.id, note: '');
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

  /// 异步加载发送者信息
  /// 用户和服务号分别调用不同接口
  Future<void> _loadSenderInfo() async {
    final senderId = widget.message.senderBipupuId;
    final isService = !_isNumeric(senderId);
    try {
      if (isService) {
        final service = await ApiClient.instance.api.serviceAccounts
            .getApiServiceAccountsName(name: senderId);
        if (mounted) setState(() => _senderServiceInfo = service);
      } else {
        final user = await ApiClient.instance.api.users
            .getApiUsersUsersBipupuId(bipupuId: senderId);
        if (mounted) setState(() => _senderUserInfo = user);
      }
    } catch (e) {
      debugPrint('Failed to load sender info for $senderId: $e');
    }
  }

  bool _isNumeric(String str) {
    // 检查是否为纯数字（不包含点号等特殊字符）
    // 000001 会被判定为用户（纯数字）
    // cosmic.fortune 会被判定为服务号（包含点号）
    return str.isNotEmpty && RegExp(r'^\d+$').hasMatch(str);
  }

  /// 复制消息内容到剪贴板
  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('message_copied'.tr())));
    }
  }

  /// 显示更多操作菜单
  void _showMoreActions() {
    final msg = widget.message;
    final currentUser = AuthService().currentUser;
    final isSender = msg.senderBipupuId == currentUser?.bipupuId;
    final isServiceAccount = !_isNumeric(msg.senderBipupuId);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.copy, color: _primaryColor),
              title: Text('copy_message'.tr()),
              onTap: () {
                Navigator.pop(context);
                _copyMessage();
              },
            ),
            if (!isSender)
              ListTile(
                leading: Icon(Icons.person_add_outlined, color: _primaryColor),
                title: Text('add_contact_button'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _addContact();
                },
              ),
            if (!isSender && !isServiceAccount)
              ListTile(
                leading: Icon(
                  Icons.block,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('block_user_button'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final currentUser = AuthService().currentUser;
    final isSender = msg.senderBipupuId == currentUser?.bipupuId;
    final isServiceAccount = !_isNumeric(msg.senderBipupuId);

    // 显示名：用户取昵称/用户名，服务号取 name
    final String displayName = isServiceAccount
        ? (_senderServiceInfo?.name ?? msg.senderBipupuId)
        : (_senderUserInfo?.nickname ??
              _senderUserInfo?.username ??
              msg.senderBipupuId);

    // 副标题：用户显示 ID，服务号显示描述
    final String? subtitle = isServiceAccount
        ? (_senderServiceInfo?.description?.isNotEmpty == true
              ? _senderServiceInfo!.description
              : null)
        : msg.senderBipupuId;

    // 头像 URL：用户和服务号使用不同接口返回的 avatarUrl
    final String? avatarUrl = isServiceAccount
        ? _senderServiceInfo?.avatarUrl
        : _senderUserInfo?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('message_detail_title'.tr()),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_outline,
              color: _isFavorited ? Colors.red : null,
            ),
            onPressed: _isLoadingFavorite ? null : _toggleFavorite,
            tooltip: _isFavorited
                ? 'action_unfavorite'.tr()
                : 'action_favorite'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreActions,
            tooltip: 'more_actions'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发送者信息卡片 - 优化设计
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isServiceAccount
                        ? null
                        : () => context.push(
                            '/user/detail/${msg.senderBipupuId}',
                          ),
                    child: UserAvatar(
                      avatarUrl: avatarUrl,
                      displayName: displayName,
                      radius: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _onSurfaceColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isServiceAccount
                                ? Colors.purple.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isServiceAccount
                                ? 'service_account'.tr()
                                : 'user'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isServiceAccount
                                  ? Colors.purple
                                  : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(msg.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSender && !isServiceAccount)
                    Container(
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.person_add_outlined,
                          color: _primaryColor,
                          size: 20,
                        ),
                        onPressed: _isLoadingContact ? null : _addContact,
                        tooltip: 'add_contact_button'.tr(),
                        splashRadius: 20,
                      ),
                    ),
                ],
              ),
            ),

            // 声纹可视化区域
            if (msg.waveform != null && msg.waveform!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 14,
                              color: _primaryColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '语音声纹',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor.withValues(alpha: 0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      WaveformVisualizationWidget(
                        waveformData: msg.waveform!,
                        width: MediaQuery.of(context).size.width - 32,
                        height: 88,
                        waveColor: _primaryColor,
                        backgroundColor: Colors.transparent,
                        showGrid: false,
                        showLabels: false,
                        smooth: true,
                        onCopyImage: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('waveform_copied'.tr())),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
                        child: Text(
                          '长按声纹图可复制',
                          style: TextStyle(
                            fontSize: 11,
                            color: _primaryColor.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 消息内容区域 - 优化设计
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'message_content'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SelectionArea(
                      child: Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: _onSurfaceColor,
                          wordSpacing: 1.2,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 主要操作按钮 - 优化为浮动按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _copyMessage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy, size: 18),
                          const SizedBox(width: 8),
                          Text('copy_message'.tr()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFavorited
                                ? 'action_unfavorite'.tr()
                                : 'action_favorite'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
