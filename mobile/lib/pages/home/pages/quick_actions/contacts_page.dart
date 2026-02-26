import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/network/network.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _contacts = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.api.contacts.getApiContacts(
        page: 1,
        pageSize: 100,
      );
      if (mounted) {
        setState(() {
          _contacts = response.contacts;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final user = await ApiClient.instance.api.users.getApiUsersUsersBipupuId(
        bipupuId: query,
      );
      if (mounted) {
        setState(() {
          _searchResults = [user];
          _isSearching = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _error = e.message;
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addContact(String contactId) async {
    try {
      await ApiClient.instance.api.contacts.postApiContacts(
        body: ContactCreate(contactId: contactId),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('contact_added'.tr())));
        _loadContacts();
        _searchController.clear();
        setState(() {
          _searchResults = [];
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('add_contact_failed'.tr(args: [e.message]))),
        );
      }
    }
  }

  Future<void> _removeContact(String contactId) async {
    try {
      await ApiClient.instance.api.contacts.deleteApiContactsContactId(
        contactId: contactId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('contact_removed'.tr())));
        _loadContacts();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('remove_contact_failed'.tr(args: [e.message])),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('contacts'.tr()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadContacts),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_user'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  _searchUsers(value);
                }
              },
            ),
          ),
          // 搜索结果或联系人列表
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 显示搜索结果
    if (_searchController.text.isNotEmpty) {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'unknown_error'.tr()),
            ],
          ),
        );
      }

      if (_searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('no_user_found'.tr()),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          final isContact = _contacts.any((c) => c.contactId == user.bipupuId);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.nickname?.substring(0, 1) ??
                      user.username.substring(0, 1).toUpperCase(),
                ),
              ),
              title: Text(user.nickname ?? user.username),
              subtitle: Text('ID: ${user.bipupuId}'),
              trailing: isContact
                  ? ElevatedButton.icon(
                      onPressed: () => _removeContact(user.bipupuId),
                      icon: const Icon(Icons.person_remove),
                      label: Text('remove'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _addContact(user.bipupuId),
                      icon: const Icon(Icons.person_add),
                      label: Text('add'.tr()),
                    ),
              onTap: () {
                context.push('/user/detail/${user.bipupuId}');
              },
            ),
          );
        },
      );
    }

    // 显示联系人列表
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'unknown_error'.tr()),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadContacts, child: Text('retry'.tr())),
          ],
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('no_contacts'.tr()),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).requestFocus(FocusNode());
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.person_add),
              label: Text('add_contact'.tr()),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                contact.contactNickname?.substring(0, 1) ??
                    contact.contactUsername.substring(0, 1).toUpperCase(),
              ),
            ),
            title: Text(
              contact.alias ??
                  contact.contactNickname ??
                  contact.contactUsername,
            ),
            subtitle: Text('ID: ${contact.contactId}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeContact(contact.contactId),
            ),
            onTap: () {
              context.push('/user/detail/${contact.contactId}');
            },
          ),
        );
      },
    );
  }
}
