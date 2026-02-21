import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/api/auth_api.dart';
import 'package:flutter_user/api/user_api.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:flutter_user/models/user/user_request.dart';
import 'dart:io';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  late final AuthApi _authApi = AuthApi();
  late final UserApi _userApi = UserApi();

  Future<User> getMe() async {
    final userData = await _authApi.getMe();
    // Convert UserResponse to User if they are different, or UserResponse is aliased.
    // Assuming User.fromJson can digest the same json.
    return User.fromJson(userData.toJson());
  }

  Future<User> uploadAvatar(File file) async {
    // AuthApi takes filePath
    final userData = await _authApi.updateAvatar(file.path);
    return User.fromJson(userData.toJson());
  }

  Future<User> updateProfile({
    String? nickname,
    String? username,
    String? email,
    Map<String, dynamic>? cosmicProfile,
  }) async {
    final userData = await _authApi.updateProfile(
      UserUpdateRequest(
        nickname: nickname,
        username: username,
        email: email,
        cosmicProfile: cosmicProfile,
      ),
    );
    return User.fromJson(userData.toJson());
  }

  /// 更新推送时间设置
  Future<User> updatePushTime({required String fortuneTime}) async {
    final userData = await _userApi.updatePushTime(fortuneTime: fortuneTime);
    return User.fromJson(userData.toJson());
  }

  /// 更新时区设置
  Future<User> updateTimezone({required String timezone}) async {
    final userData = await _userApi.updateTimezone(timezone: timezone);
    return User.fromJson(userData.toJson());
  }

  /// 获取推送设置信息
  Future<Map<String, dynamic>> getPushSettings() async {
    return await _userApi.getPushSettings();
  }
}
