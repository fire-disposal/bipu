import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart'; // for bipupuHttp
import 'package:flutter_user/api/user_api.dart';
import 'package:flutter_user/api/block_api.dart';
import 'package:flutter_user/models/user/user_response.dart';
import 'package:easy_localization/easy_localization.dart';

class UserDetailPage extends StatefulWidget {
  final String bipupuId;

  const UserDetailPage({super.key, required this.bipupuId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late final UserApi _userApi = UserApi(bipupuHttp);
  late final BlockApi _blockApi = BlockApi(bipupuHttp);

  UserResponse? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await _userApi.getUserByBipupuId(widget.bipupuId);
      setState(() {
        _user = userData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _blockUser() async {
    if (_user == null) return;
    try {
      await _blockApi.blockUser(_user!.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('blocked'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('block_failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $_error')),
      );
    }
    if (_user == null) {
      return Scaffold(body: Center(child: Text('user_not_found'.tr())));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_user!.nickname ?? _user!.username)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                _user!.nickname?.substring(0, 1) ??
                    _user!.username.substring(0, 1),
              ),
            ),
            const SizedBox(height: 16),
            Text('ID: ${_user!.id}'),
            const SizedBox(height: 16),
            if (_user!.cosmicProfile != null)
              Text('Profile: ${_user!.cosmicProfile}'),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _blockUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('block_user'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
