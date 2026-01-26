import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core/models/user_model.dart';
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
        title: const Text(
          'Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
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

          return ListView(
            children: [
              _buildSystemItem(
                context,
                Icons.group_add,
                'New Friends',
                Colors.orange,
                badgeCount: requestCount,
                onTap: () => context.go('/contacts/requests'),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Friends',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (friends.isEmpty && state is! FriendshipLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("No friends yet")),
                ),
              ...friends.map((user) => _buildContactItem(user)),
            ],
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
        context.push('/chat/${user.id}');
      },
    );
  }
}
