import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/im_service.dart';
import '../../../models/friendship/friendship_response.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ImService _imService = ImService();

  @override
  void initState() {
    super.initState();
    // 监听IM服务状态变化
    _imService.addListener(_onImServiceChanged);

    // 如果还没有启动定时任务，则启动
    _imService.startPolling();
  }

  @override
  void dispose() {
    _imService.removeListener(_onImServiceChanged);
    super.dispose();
  }

  void _onImServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendships = _imService.friendships;
    final friendRequests = _imService.friendRequests;
    final isLoading = _imService.isLoading;

    // 筛选出已接受的好友
    final acceptedFriends = friendships
        .where((f) => f.status.toString().toLowerCase() == 'accepted')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: '搜索好友',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('搜索功能开发中...')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => _imService.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _imService.refresh(),
        child: isLoading && acceptedFriends.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _buildSystemItem(
                    context,
                    Icons.person_add_rounded,
                    '新的朋友',
                    Colors.orange.shade700,
                    badgeCount: friendRequests.length,
                    onTap: () => _showFriendRequests(context),
                  ),
                  _buildSystemItem(
                    context,
                    Icons.group_rounded,
                    '群聊',
                    Colors.green.shade600,
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('群聊功能开发中...'))),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 24, bottom: 8),
                    child: Text(
                      '我的好友',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (acceptedFriends.isEmpty && !isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "暂无好友，快去搜索添加吧",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...acceptedFriends.map(
                    (friendship) => _buildContactItem(context, friendship),
                  ),
                  if (isLoading && acceptedFriends.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildSystemItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    FriendshipResponse friendship,
  ) {
    final displayName = 'Friend ${friendship.friendId}';
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: _getAvatarColor(friendship.friendId),
        child: Text(
          avatarLetter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '好友ID: ${friendship.friendId}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
      onTap: () => _showContactActions(context, friendship),
    );
  }

  Color _getAvatarColor(int userId) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];
    return colors[userId % colors.length];
  }

  void _showFriendRequests(BuildContext context) {
    final friendRequests = _imService.friendRequests;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      '好友请求',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (friendRequests.isNotEmpty)
                      Text(
                        '${friendRequests.length}个请求',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: friendRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_disabled,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无好友请求',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: friendRequests.length,
                        itemBuilder: (context, index) {
                          final request = friendRequests[index];
                          return _buildFriendRequestItem(context, request);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestItem(
    BuildContext context,
    FriendshipResponse request,
  ) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: _getAvatarColor(request.userId),
        child: Text(
          'U${request.userId}'.substring(0, 1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text('用户 ${request.userId}'),
      subtitle: Text(
        '${_formatTime(request.createdAt)}发送请求',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () async {
              final success = await _imService.rejectFriendRequest(request.id);
              if (success && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已拒绝好友请求')));
                Navigator.pop(context);
              }
            },
            child: const Text('拒绝'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _imService.acceptFriendRequest(request.id);
              if (success && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已接受好友请求')));
                Navigator.pop(context);
              }
            },
            child: const Text('接受'),
          ),
        ],
      ),
    );
  }

  void _showContactActions(
    BuildContext context,
    FriendshipResponse friendship,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('发起聊天'),
              onTap: () {
                Navigator.pop(context);
                context.push('/messages/chat/${friendship.friendId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.call),
              title: const Text('语音对讲'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('正在发起对讲...')));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
