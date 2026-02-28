import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/im_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/api/models/service_account_response.dart';

class SystemMessagesPage extends StatefulWidget {
  const SystemMessagesPage({super.key});

  @override
  State<SystemMessagesPage> createState() => _SystemMessagesPageState();
}

class _SystemMessagesPageState extends State<SystemMessagesPage> {
  final ImService _imService = ImService();
  List<MessageResponse> _messages = [];
  Map<String, ServiceAccountResponse?> _serviceCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  /// 获取服务号信息（带缓存）
  Future<ServiceAccountResponse?> _getServiceAccount(String serviceName) async {
    // 先从缓存获取
    if (_serviceCache.containsKey(serviceName)) {
      return _serviceCache[serviceName];
    }

    try {
      final service = await ApiClient.instance.api.serviceAccounts
          .getApiServiceAccountsName(name: serviceName);
      _serviceCache[serviceName] = service;
      return service;
    } on ApiException catch (e) {
      debugPrint('Failed to load service account $serviceName: ${e.message}');
      _serviceCache[serviceName] = null;
      return null;
    }
  }

  /// 构建服务号头像
  Widget _buildServiceAvatar(ServiceAccountResponse service) {
    if (service.avatarUrl != null && service.avatarUrl!.isNotEmpty) {
      final avatarUrl = service.avatarUrl!.startsWith('http')
          ? service.avatarUrl!
          : '${ApiClient.instance.dio.options.baseUrl}${service.avatarUrl}';

      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Failed to load avatar: $exception');
        },
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.orange.withValues(alpha: 0.2),
      child: Text(
        service.name.isNotEmpty ? service.name[0].toUpperCase() : '?',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
      ),
    );
  }

  /// 默认系统图标
  Widget _buildDefaultSystemIcon() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.orange.withValues(alpha: 0.2),
      child: Icon(Icons.notifications, color: Colors.orange, size: 24),
    );
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.api.messages.getApiMessages();
      final filtered = response.messages
          .where((msg) => msg.messageType == MessageType.system)
          .toList();
      setState(() {
        _messages = filtered;
      });

      // 预加载服务号信息
      for (final msg in _messages) {
        if (!_serviceCache.containsKey(msg.senderBipupuId)) {
          _getServiceAccount(msg.senderBipupuId);
        }
      }
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
    // Sort messages by latest first
    final List<MessageResponse> messages = List.from(_messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text('messages_menu_system'.tr()),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'no_messages'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _loadMessages(),
              child: ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isRead = _imService.isMessageRead(msg.id);

                  return FutureBuilder<ServiceAccountResponse?>(
                    future: _getServiceAccount(msg.senderBipupuId),
                    builder: (context, snapshot) {
                      final service = snapshot.data;
                      final displayName = service?.name ?? msg.senderBipupuId;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () async {
                            await _imService.markMessageAsRead(msg.id);
                            if (mounted) {
                              context.push('/messages/detail', extra: msg);
                            }
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Wrap(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      isRead ? Icons.mail : Icons.mail_outline,
                                    ),
                                    title: Text(
                                      isRead
                                          ? 'mark_unread'.tr()
                                          : 'mark_read'.tr(),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (isRead) {
                                        _imService.markMessageAsUnread(msg.id);
                                      } else {
                                        _imService.markMessageAsRead(msg.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    if (service != null)
                                      _buildServiceAvatar(service)
                                    else if (snapshot.connectionState ==
                                        ConnectionState.waiting)
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    else
                                      _buildDefaultSystemIcon(),
                                    if (!isRead)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.bold,
                                                fontSize: 14,
                                                color: service != null
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat(
                                              'MM-dd HH:mm',
                                            ).format(msg.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isRead
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
