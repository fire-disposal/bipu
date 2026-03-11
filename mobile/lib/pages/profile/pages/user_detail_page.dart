import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import '../../../../core/api/models/block_user_request.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/user_avatar.dart';

class UserDetailPage extends StatefulWidget {
  final String bipupuId;

  const UserDetailPage({super.key, required this.bipupuId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  dynamic _user;
  bool _isLoading = true;
  String? _error;

  /// 构建用户头像
  Widget _buildUserAvatar({double radius = 40}) {
    return UserAvatar(
      bipupuId: widget.bipupuId,
      displayName: _user?.nickname ?? _user?.username ?? '?',
      radius: radius,
      backgroundColor: Colors.grey.withValues(alpha: 0.3),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await ApiClient.instance.api.users
          .getApiUsersUsersBipupuId(bipupuId: widget.bipupuId);
      setState(() {
        _user = userData;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _blockUser() async {
    if (_user == null) return;
    // 支持 Map 或者 model 对象
    final bipupu = _user is Map ? _user['bipupuId'] : (_user.bipupuId ?? null);
    if (bipupu == null) return;
    try {
      await ApiClient.instance.api.blacklist.postApiBlocks(
        body: BlockUserRequest(bipupuId: bipupu),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('blocked'.tr())));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('block_failed'.tr(args: [e.message]))),
        );
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
            _buildUserAvatar(),
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
