import 'package:bipupu/api/api.dart';
import 'package:bipupu/api/auth_api.dart';
import 'package:bipupu/api/user_api.dart';
import 'package:bipupu/models/user/user_response.dart';
import 'package:bipupu/models/user/user_request.dart';
import 'dart:io';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  late final AuthApi _authApi = AuthApi();
  late final UserApi _userApi = UserApi();

  Future<UserResponse> getMe() async {
    final userData = await _authApi.getMe();
    return userData;
  }

  Future<UserResponse> uploadAvatar(File file) async {
    final userData = await _authApi.updateAvatar(file.path);
    return userData;
  }

  Future<UserResponse> updateProfile({
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
    return userData;
  }

  /// 更新推送时间设置
  Future<UserResponse> updatePushTime({required String fortuneTime}) async {
    final userData = await _userApi.updatePushTime(fortuneTime: fortuneTime);
    return userData;
  }

  /// 更新时区设置
  Future<UserResponse> updateTimezone({required String timezone}) async {
    final userData = await _userApi.updateTimezone(timezone: timezone);
    return userData;
  }

  /// 获取推送设置信息
  Future<Map<String, dynamic>> getPushSettings() async {
    return await _userApi.getPushSettings();
  }
}
