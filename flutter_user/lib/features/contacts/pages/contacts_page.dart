import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_bloc.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_event.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_state.dart';
import 'package:go_router/go_router.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<FriendshipBloc>();
    if (bloc.state is FriendshipInitial) {
      bloc.add(const LoadFriendships());
      bloc.add(const LoadFriendRequests());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系�?, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: '搜索好友',
            onPressed: () {
              context.go('/contacts/search');
            },
          ),
        ],
      ),
      body: BlocBuilder<FriendshipBloc, FriendshipState>(
        builder: (context, state) {
          int requestCount = 0;
          List<User> friends = [];
          if (state is FriendshipLoaded) {
            friends = state.friends;
            requestCount = state.requestsCount;
          }

          if (state is FriendshipLoading && friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FriendshipBloc>().add(const LoadFriendships());
              context.read<FriendshipBloc>().add(const LoadFriendRequests());
            },
            child: ListView(
              children: [
                _buildSystemItem(
                  context,
                  Icons.person_add_rounded,
                  '新的朋友',
                  Colors.orange.shade700,
                  badgeCount: requestCount,
                  onTap: () => context.go('/contacts/requests'),
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
                if (friends.isEmpty && state is! FriendshipLoading)
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
                ...friends.map((user) => _buildContactItem(user)),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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
          : null,
      onTap: onTap ?? () {},
    );
  }

  Widget _buildContactItem(User user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      title: Text(
        user.nickname ?? user.username,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
      onTap: () {
        context.push('/user/detail/${user.id}');
      },
    );
  }
}
