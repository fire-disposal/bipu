import 'package:dio/dio.dart';
import 'package:flutter_user/models/auth/token.dart';
import 'package:flutter_user/models/user/user_response.dart';
import 'package:flutter_user/models/user/user_request.dart';
import 'package:flutter_user/models/user/user_password_update.dart';
import 'package:flutter_user/models/user/timezone_update.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Token> login(Map<String, dynamic> body) async {
    final response = await _dio.post('/api/public/login', data: body);
    return Token.fromJson(response.data);
  }

  Future<Token> register(Map<String, dynamic> body) async {
    final response = await _dio.post('/api/public/register', data: body);
    return Token.fromJson(response.data);
  }

  Future<Token> refreshToken(Map<String, dynamic> body) async {
    final response = await _dio.post('/api/public/refresh', data: body);
    return Token.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/api/public/logout');
  }

  Future<UserResponse> getMe() async {
    final response = await _dio.get('/api/profile/me');
    return UserResponse.fromJson(response.data);
  }

  Future<bool> verifyToken() async {
    final response = await _dio.get('/api/public/verify-token');
    return response.data['valid'] == true;
  }

  Future<UserResponse> updateProfile(UserUpdateRequest body) async {
    final response = await _dio.put('/api/profile/', data: body.toJson());
    return UserResponse.fromJson(response.data);
  }

  Future<void> updatePassword(UserPasswordUpdate body) async {
    await _dio.put('/api/profile/password', data: body.toJson());
  }

  Future<void> updateTimezone(TimezoneUpdate body) async {
    await _dio.put('/api/profile/timezone', data: body.toJson());
  }

  Future<Map<String, dynamic>> getPushSettings() async {
    final response = await _dio.get('/api/profile/push-settings');
    return response.data;
  }

  Future<UserResponse> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/profile/avatar', data: formData);
    return UserResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getUserAvatar(String bipupuId) async {
    final response = await _dio.get('/api/users/$bipupuId/avatar');
    return response.data;
  }

  Future<Map<String, dynamic>> getProfileAvatar(String bipupuId) async {
    final response = await _dio.get('/api/profile/avatar/$bipupuId');
    return response.data;
  }
}
