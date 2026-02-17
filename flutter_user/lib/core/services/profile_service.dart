import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/api/auth_api.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:flutter_user/models/user/user_request.dart';
import 'dart:io';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  late final AuthApi _api = AuthApi();

  Future<User> getMe() async {
    final userData = await _api.getMe();
    // Convert UserResponse to User if they are different, or UserResponse is aliased.
    // Assuming User.fromJson can digest the same json.
    return User.fromJson(userData.toJson());
  }

  Future<User> uploadAvatar(File file) async {
    // AuthApi takes filePath
    final userData = await _api.updateAvatar(file.path);
    return User.fromJson(userData.toJson());
  }

  Future<User> updateProfile({
    String? nickname,
    String? username,
    String? email,
    Map<String, dynamic>? cosmicProfile,
  }) async {
    final userData = await _api.updateProfile(
      UserUpdateRequest(
        nickname: nickname,
        username: username,
        email: email,
        cosmicProfile: cosmicProfile,
      ),
    );
    return User.fromJson(userData.toJson());
  }
}
