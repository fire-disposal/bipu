import 'package:flutter/material.dart';
import 'package:flutter_core/models/user_model.dart';
import 'package:flutter_core/repositories/user_repository.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserRepository _userRepository = UserRepository();
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _total = 0;
  final int _pageSize = 10;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _userRepository.getUsers(
        page: _currentPage,
        size: _pageSize,
        search: _searchQuery,
      );
      setState(() {
        _users = response.items;
        _total = response.total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      _currentPage = 1;
    });
    _loadUsers();
  }

  Future<void> _showUserDialog([User? user]) async {
    await showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: user,
        onSave: (data) async {
          try {
            if (user == null) {
              await _userRepository.createUser(data);
            } else {
              await _userRepository.updateUser(user.id, data);
            }
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(user == null ? 'User created' : 'User updated'),
                ),
              );
            }
            if (mounted) {
              _loadUsers();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      await _userRepository.updateUser(user.id, {'is_active': !user.isActive});
      if (mounted) {
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showUserDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Users',
              hintText: 'Search by username or email',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearch();
                },
              ),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _users.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(Text(user.id.toString())),
                        DataCell(Text(user.username)),
                        DataCell(Text(user.email)),
                        DataCell(Text(user.isSuperuser ? 'Admin' : 'User')),
                        DataCell(
                          Chip(
                            label: Text(user.isActive ? 'Active' : 'Inactive'),
                            backgroundColor: user.isActive
                                ? Colors.green[100]
                                : Colors.red[100],
                            labelStyle: TextStyle(
                              color: user.isActive
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showUserDialog(user),
                              ),
                              IconButton(
                                icon: Icon(
                                  user.isActive
                                      ? Icons.block
                                      : Icons.check_circle,
                                ),
                                color: user.isActive
                                    ? Colors.red
                                    : Colors.green,
                                onPressed: () => _toggleUserStatus(user),
                                tooltip: user.isActive
                                    ? 'Block User'
                                    : 'Activate User',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Page $_currentPage of ${(_total / _pageSize).ceil()}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadUsers();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage * _pageSize < _total
                    ? () {
                        setState(() => _currentPage++);
                        _loadUsers();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final User? user;
  final Function(Map<String, dynamic>) onSave;

  const _UserDialog({this.user, required this.onSave});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nicknameController;
  bool _isSuperuser = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username);
    _emailController = TextEditingController(text: widget.user?.email);
    _passwordController = TextEditingController();
    _nicknameController = TextEditingController(text: widget.user?.nickname);
    _isSuperuser = widget.user?.isSuperuser ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              if (widget.user == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              CheckboxListTile(
                title: const Text('Is Admin'),
                value: _isSuperuser,
                onChanged: (v) => setState(() => _isSuperuser = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'username': _usernameController.text,
                'email': _emailController.text,
                'nickname': _nicknameController.text,
                'is_superuser': _isSuperuser,
              };
              if (widget.user == null) {
                data['password'] = _passwordController.text;
              }
              widget.onSave(data);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
