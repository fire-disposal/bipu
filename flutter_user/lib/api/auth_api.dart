import 'package:dio/dio.dart';
import 'core/api_client.dart';
import '../models/auth/token.dart';
import '../models/auth/auth_request.dart';
import '../models/user/user_response.dart';
import '../models/user/user_request.dart';

class AuthApi {
  final ApiClient _api;

  AuthApi([ApiClient? api]) : _api = api ?? ApiClient();

  Future<Token> login(LoginRequest body) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/public/login',
      data: body.toJson(),
    );
    return Token.fromJson(response);
  }

  Future<UserResponse> register(RegisterRequest body) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/public/register',
      data: body.toJson(),
    );
    return UserResponse.fromJson(response);
  }

  Future<Token> refreshToken(RefreshTokenRequest body) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/public/refresh',
      data: body.toJson(),
    );
    return Token.fromJson(response);
  }

  Future<void> logout() async {
    await _api.post('/api/public/logout');
  }

  Future<UserResponse> getMe() async {
    final response = await _api.get<Map<String, dynamic>>('/api/profile/me');
    return UserResponse.fromJson(response);
  }

  Future<UserResponse> updateProfile(UserUpdateRequest body) async {
    final response = await _api.put<Map<String, dynamic>>(
      '/api/profile/',
      data: body.toJson(),
    );
    return UserResponse.fromJson(response);
  }

  Future<UserResponse> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _api.upload<Map<String, dynamic>>(
      '/api/profile/avatar',
      formData,
    );
    return UserResponse.fromJson(response);
  }
}
