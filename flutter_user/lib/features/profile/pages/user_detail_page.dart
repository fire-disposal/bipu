import 'package:flutter/material.dart';
import 'package:flutter_user/api/api.dart';
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
  late final UserApi _userApi = UserApi();
  late final BlockApi _blockApi = BlockApi();

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
            Text('Bipupu ID: ${_user!.bipupuId}'),
            const SizedBox(height: 16),
            if (_user!.cosmicProfile != null) ...[
              if (_user!.cosmicProfile!['gender'] != null)
                Text('性别: ${_user!.cosmicProfile!['gender']}'),
              if (_user!.cosmicProfile!['birthday'] != null)
                Text('生日: ${_user!.cosmicProfile!['birthday']}'),
              if (_user!.cosmicProfile!['age'] != null)
                Text('年龄: ${_user!.cosmicProfile!['age']}'),
              if (_user!.cosmicProfile!['zodiac'] != null)
                Text('星座: ${_user!.cosmicProfile!['zodiac']}'),
              if (_user!.cosmicProfile!['bazi'] != null)
                Text('生辰八字: ${_user!.cosmicProfile!['bazi']}'),
              if (_user!.cosmicProfile!['mbti'] != null)
                Text('MBTI: ${_user!.cosmicProfile!['mbti']}'),
              if (_user!.cosmicProfile!['birth_time'] != null)
                Text('出生时间: ${_user!.cosmicProfile!['birth_time']}'),
              if (_user!.cosmicProfile!['birthplace'] != null)
                Text('出生地: ${_user!.cosmicProfile!['birthplace']}'),
              const SizedBox(height: 16),
            ],

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
