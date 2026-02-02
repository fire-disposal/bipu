import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/models/user_model.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _api = bipupuApi;

  Future<User> getMe() => _api.getMe();

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
