import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core/models/user_model.dart';
import 'package:flutter_core/repositories/user_repository.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_bloc.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_event.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _searchController = TextEditingController();
  List<User> _results = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _search(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _userRepository.getUsers(search: query);
      setState(() {
        _results = response.items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(user.nickname ?? user.username),
                  subtitle: Text(user.username),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      // TODO: Check if already friends
                      context.read<FriendshipBloc>().add(
                        SendFriendRequest(user.id),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Friend request sent to ${user.username}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
