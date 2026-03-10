import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/im_service.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/models/message_response.dart';
import '../../../../core/api/models/contact_create.dart';
import '../../../../core/api/models/block_user_request.dart';
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

  Color get _onSurfaceColor => Theme.of(context).colorScheme.onSurface;
  Color get _cardColor =>
      Theme.of(context).cardTheme.color ?? Colors.transparent;
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _dividerColor => Theme.of(context).dividerColor;
  Color get _iconColor => Theme.of(context).iconTheme.color ?? Colors.black;
  Color get _surfaceContainerHigh => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _surfaceContainerLow => Theme.of(context).colorScheme.surfaceContainerLow;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('message_copied'.tr())),
      );
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
                leading: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
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

    // TODO: 从联系人缓存获取发送者信息，暂时使用消息中的 ID
    final displayName = msg.senderBipupuId;

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
            tooltip: _isFavorited ? 'action_unfavorite'.tr() : 'action_favorite'.tr(),
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
                    color: Colors.black.withOpacity(0.1),
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
                    onTap: () {
                      context.push('/user/detail/${msg.senderBipupuId}');
                    },
                    child: UserAvatar(
                      bipupuId: msg.senderBipupuId,
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
                        Text(
                          msg.senderBipupuId,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isServiceAccount 
                                ? Colors.purple.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isServiceAccount ? 'service_account'.tr() : 'user'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isServiceAccount ? Colors.purple : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(msg.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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

            // 声纹信息区域 - 重点优化
            if (msg.waveform != null && msg.waveform!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'voice_waveform'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _onSurfaceColor,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // 显示波形详细信息
                                _showWaveformInfo(msg.waveform!);
                              },
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: Text('details'.tr(), style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: WaveformVisualizationWidget(
                            waveformData: msg.waveform!,
                            width: MediaQuery.of(context).size.width - 64,
                            height: 140,
                            waveColor: _primaryColor,
                            backgroundColor: _surfaceContainerLow,
                            showGrid: true,
                            showLabels: true,
                            onCopyImage: () {
                              // 波形图复制成功提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('waveform_copied'.tr())),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 声纹统计信息
                        _buildWaveformStats(msg.waveform!),
                      ],
                    ),
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
                      border: Border.all(color: _dividerColor.withOpacity(0.3)),
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
                            _isFavorited ? Icons.favorite : Icons.favorite_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFavorited ? 'action_unfavorite'.tr() : 'action_favorite'.tr(),
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

  /// 构建波形统计信息
  Widget _buildWaveformStats(List<int> waveformData) {
    if (waveformData.isEmpty) return const SizedBox();

    final min = waveformData.reduce((a, b) => a < b ? a : b);
    final max = waveformData.reduce((a, b) => a > b ? a : b);
    final avg = waveformData.reduce((a, b) => a + b) / waveformData.length;
    final dynamicRange = max - min;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'waveform_stats'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatItem('points'.tr(), '${waveformData.length}'),
              _buildStatItem('max_amplitude'.tr(), '$max'),
              _buildStatItem('min_amplitude'.tr(), '$min'),
              _buildStatItem('avg_amplitude'.tr(), avg.toStringAsFixed(1)),
              _buildStatItem('dynamic_range'.tr(), '$dynamicRange'),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _onSurfaceColor,
          ),
        ),
      ],
    );
  }

  /// 显示波形详细信息对话框
  void _showWaveformInfo(List<int> waveformData) {
    final min = waveformData.reduce((a, b) => a < b ? a : b);
    final max = waveformData.reduce((a, b) => a > b ? a : b);
    final avg = waveformData.reduce((a, b) => a + b) / waveformData.length;
    final dynamicRange = max - min;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('waveform_details'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('data_points'.tr(), '${waveformData.length}'),
              _buildInfoRow('max_value'.tr(), '$max'),
              _buildInfoRow('min_value'.tr(), '$min'),
              _buildInfoRow('average_value'.tr(), avg.toStringAsFixed(2)),
              _buildInfoRow('dynamic_range'.tr(), '$dynamicRange'),
              _buildInfoRow('data_size'.tr(), '${waveformData.length} bytes'),
              const SizedBox(height: 16),
              Text(
                'waveform_tip'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
