import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/user_model.dart';
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
      final user = await bipupuApi.adminGetUser(widget.userId);
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
            onPressed: () {
              // TODO: 更多操作（拉黑等�?
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
                      label: const Text('发送消�?),
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
    final theme = Theme.of(context);
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
