import 'package:flutter/material.dart';
import 'package:bipupu/api/api.dart';
import 'package:bipupu/api/user_api.dart';
import 'package:bipupu/core/services/im_service.dart';
import 'package:bipupu/core/widgets/user_avatar.dart';
import 'package:bipupu/models/user/user_response.dart';
import 'package:easy_localization/easy_localization.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  late final UserApi _userApi = UserApi();
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
                  leading: UserAvatarSmall(
                    avatarUrl: _result!.avatarUrl,
                    displayName: _result!.nickname ?? _result!.username,
                    size: 40,
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
