import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/api/user_api.dart';
import 'package:flutter_user/api/block_api.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/models/user/user_response.dart';
import 'package:easy_localization/easy_localization.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  late final UserApi _userApi = UserApi(bipupuHttp);
  late final ImService _imService = ImService();
  final TextEditingController _searchController = TextEditingController();
  UserResponse? _result;
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
      final user = await _userApi.getUserByBipupuId(query);
      setState(() {
        _result = user;
      });
    } catch (e) {
      setState(() {
        _error = 'user_not_found'.tr(); // e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    if (_result == null) return;
    try {
      await _imService.contactApi.addContact(_result!.bipupuId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('add_success'.tr())));
        // Logic to refresh contacts list or navigate back
        _imService.refresh(); // assume this refreshes contacts too
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('add_failed'.tr(args: [e.toString()]))),
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
