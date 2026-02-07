import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/models/user_model.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _api = bipupuApi;

  Future<User> getMe() => _api.getMe();

  Future<User> uploadAvatar(File file) async {
    final fileName = file.path.split('/').last;
    final multipartFile = await MultipartFile.fromFile(
      file.path,
      filename: fileName,
    );
    return _api.updateAvatar(multipartFile);
  }

  Future<User> updateProfile({
    String? nickname,
    String? username,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    return _api.updateMe(body);
  }
}
