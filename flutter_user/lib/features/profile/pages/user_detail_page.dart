import 'package:flutter/material.dart';
import 'package:bipupu/api/api.dart';
import 'package:bipupu/models/user/user_response.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/user_avatar.dart';

class UserDetailPage extends StatefulWidget {
  final String bipupuId;

  const UserDetailPage({super.key, required this.bipupuId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserApi _userApi = UserApi();
  final BlockApi _blockApi = BlockApi();

  UserResponse? _user;
  bool _isLoading = true;
  String? _error;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userData = await _userApi.getUserByBipupuId(widget.bipupuId);
      final currentUser = AuthService().currentUser;

      if (mounted) {
        setState(() {
          _user = userData;
          _isOwnProfile =
              currentUser != null && currentUser.bipupuId == widget.bipupuId;
          _isLoading = false;
        });
      }
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('user_not_found'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_user!.nickname ?? _user!.username)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                    avatarUrl: _user!.avatarUrl,
                    displayName: _user!.nickname ?? _user!.username,
                    radius: 36,
                    showEditIcon: _isOwnProfile,
                    onTap: _isOwnProfile
                        ? () => context.push('/profile/edit')
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoTile('Bipupu ID', _user!.bipupuId),
            if (_user!.cosmicProfile != null) ...[
              if (_user!.cosmicProfile!['gender'] != null)
                _buildInfoTile(
                  '性别',
                  _user!.cosmicProfile!['gender'].toString(),
                ),
              if (_user!.cosmicProfile!['birthday'] != null)
                _buildInfoTile(
                  '生日',
                  _user!.cosmicProfile!['birthday'].toString(),
                ),
              if (_user!.cosmicProfile!['age'] != null)
                _buildInfoTile('年龄', _user!.cosmicProfile!['age'].toString()),
              if (_user!.cosmicProfile!['zodiac'] != null)
                _buildInfoTile(
                  '星座',
                  _user!.cosmicProfile!['zodiac'].toString(),
                ),
              if (_user!.cosmicProfile!['mbti'] != null)
                _buildInfoTile(
                  'MBTI',
                  _user!.cosmicProfile!['mbti'].toString(),
                ),
              if (_user!.cosmicProfile!['birthplace'] != null)
                _buildInfoTile(
                  '出生地',
                  _user!.cosmicProfile!['birthplace'].toString(),
                ),
            ],
            if (!_isOwnProfile) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _blockUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('block_user'.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
