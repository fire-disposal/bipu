import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:easy_localization/easy_localization.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  dynamic _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final user = await ApiClient.instance.api.users.getApiUsersUsersBipupuId(
        bipupuId: query,
      );
      setState(() {
        _result = user;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    if (_result == null) return;
    try {
      await ApiClient.instance.api.contacts.postApiContacts(
        body: ContactCreate(contactId: _result.bipupuId),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('add_success'.tr())));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('add_failed'.tr(args: [e.message]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('add_contact'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'search_id_placeholder'.tr(),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      _result!.nickname?.substring(0, 1) ??
                          _result!.username.substring(0, 1),
                    ),
                  ),
                  title: Text(_result!.nickname ?? _result!.username),
                  subtitle: Text('ID: ${_result!.bipupuId}'),
                  trailing: ElevatedButton(
                    onPressed: _addContact,
                    child: Text('add_friend'.tr()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
