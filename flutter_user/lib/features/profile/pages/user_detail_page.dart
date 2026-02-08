import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:flutter_user/models/user/user_settings_request.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserDetailPage extends StatefulWidget {
  final int userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await bipupuApi.adminGetUser(widget.userId);
      final user = User.fromJson(userData.toJson());
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('用户详情')),
        body: Center(child: Text('加载失败: $_error')),
      );
    }

    final user = _user!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () async {
              final choice = await showModalBottomSheet<String>(
                context: context,
                builder: (c) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('屏蔽用户'),
                      onTap: () => Navigator.pop(c, 'block'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.report),
                      title: const Text('举报用户'),
                      onTap: () => Navigator.pop(c, 'report'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cancel),
                      title: const Text('取消'),
                      onTap: () => Navigator.pop(c, null),
                    ),
                  ],
                ),
              );

              if (choice == 'block') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('确认屏蔽'),
                    content: Text(
                      '确定要屏蔽用户 ${_user?.username ?? widget.userId} 吗？',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await bipupuApi.blockUser(
                      BlockUserRequest(userId: widget.userId),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('已屏蔽用户')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('屏蔽失败: $e')));
                    }
                  }
                }
              } else if (choice == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('感谢您的反馈，举报已提交（示例）')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Hero(
                tag: 'avatar_${user.id}',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          user.avatarUrl!.startsWith('http')
                              ? user.avatarUrl!
                              : '${bipupuHttp.options.baseUrl.replaceFirst(RegExp(r"/api$"), '')}${user.avatarUrl}',
                        )
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.nickname ?? user.username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${user.username}',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(context, user),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/chat/${user.id}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('发送消息'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoCard(BuildContext context, User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ListTile(
            title: const Text('邮箱'),
            subtitle: Text(user.email),
            leading: const Icon(Icons.email_outlined),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('注册时间'),
            subtitle: Text(
              user.createdAt?.toLocal().toString().split('.')[0] ?? '未知',
            ),
            leading: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
    );
  }
}
