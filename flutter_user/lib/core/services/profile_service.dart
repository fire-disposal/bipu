import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/api/auth_api.dart';
import 'package:flutter_user/models/user/user_response.dart';
import 'package:flutter_user/models/user/user_request.dart';
import 'dart:io';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  late final AuthApi _api = AuthApi(bipupuHttp);

  Future<UserResponse> getMe() async {
    final userData = await _api.getMe();
    return userData;
  }

  Future<UserResponse> uploadAvatar(File file) async {
    // AuthApi takes filePath
    final userData = await _api.updateAvatar(file.path);
    return userData;
  }

  Future<UserResponse> updateProfile({
    String? nickname,
    String? username,
    String? password,
    DateTime? birthday,
    String? zodiac,
    int? age,
    String? bazi,
    String? gender,
    String? mbti,
    String? birthTime,
    String? birthplace,
  }) async {
    final userData = await _api.updateProfile(
      UserUpdateRequest(
        nickname: nickname,
        username: username,
        password: password,
        birthday: birthday,
        zodiac: zodiac,
        age: age,
        bazi: bazi,
        gender: gender,
        mbti: mbti,
        birthTime: birthTime,
        birthplace: birthplace,
      ),
    );
    return userData;
  }
}
