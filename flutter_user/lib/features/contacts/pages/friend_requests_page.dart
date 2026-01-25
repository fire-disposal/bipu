import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_bloc.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_event.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_state.dart';
import 'package:intl/intl.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Friends')),
      body: BlocBuilder<FriendshipBloc, FriendshipState>(
        builder: (context, state) {
          if (state is FriendshipLoading &&
              (state as dynamic).requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FriendshipLoaded) {
            final requests = state.requests;

            if (requests.isEmpty) {
              return const Center(child: Text('No pending requests'));
            }

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final item = requests[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      item.sender.username.isNotEmpty
                          ? item.sender.username[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(item.sender.username),
                  subtitle: Text(
                    'Sent: ${DateFormat.yMMMd().format(item.friendship.createdAt)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          context.read<FriendshipBloc>().add(
                            AcceptFriendRequest(item.friendship.id),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          context.read<FriendshipBloc>().add(
                            RejectFriendRequest(item.friendship.id),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is FriendshipError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
