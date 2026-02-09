import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/core/storage/mobile_token_storage.dart';

class UserAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String? displayName;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.radius = 50,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final tokenStorage = MobileTokenStorage();
    final token = await tokenStorage.getAccessToken();
    if (mounted) {
      setState(() {
        _authToken = token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: widget.avatarUrl != null
          ? _getImageProvider(widget.avatarUrl!)
          : null,
      child: widget.avatarUrl == null ? _buildFallbackText() : null,
    );

    if (widget.onTap != null) {
      avatar = GestureDetector(onTap: widget.onTap, child: avatar);
    }

    if (widget.showEditIcon) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  ImageProvider? _getImageProvider(String url) {
    final headers = _authToken != null
        ? {'Authorization': 'Bearer $_authToken'}
        : null;

    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url, headers: headers);
    } else {
      // 相对路径，拼接基础URL
      final baseUrl = bipupuHttp.options.baseUrl.replaceFirst(
        RegExp(r'/api/?$'),
        '',
      );
      return CachedNetworkImageProvider('$baseUrl$url', headers: headers);
    }
  }

  Widget _buildFallbackText() {
    final initial = widget.displayName?.isNotEmpty == true
        ? widget.displayName![0].toUpperCase()
        : '?';

    return Text(
      initial,
      style: TextStyle(
        fontSize: widget.radius * 0.64, // 32 when radius=50
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
