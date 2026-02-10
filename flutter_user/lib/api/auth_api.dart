import 'package:dio/dio.dart';
import '../models/auth/token.dart';
import '../models/auth/auth_request.dart';
import '../models/user/user_response.dart';
import '../models/user/user_request.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Token> login(LoginRequest body) async {
    final response = await _dio.post('/api/public/login', data: body.toJson());
    return Token.fromJson(response.data);
  }

  Future<Token> register(RegisterRequest body) async {
    final response = await _dio.post(
      '/api/public/register',
      data: body.toJson(),
    );
    return Token.fromJson(response.data);
  }

  Future<Token> refreshToken(RefreshTokenRequest body) async {
    final response = await _dio.post(
      '/api/public/refresh',
      data: body.toJson(),
    );
    return Token.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/api/public/logout');
  }

  Future<UserResponse> getMe() async {
    final response = await _dio.get('/api/profile/me');
    return UserResponse.fromJson(response.data);
  }

  Future<UserResponse> updateProfile(UserUpdateRequest body) async {
    final response = await _dio.put('/api/profile/', data: body.toJson());
    return UserResponse.fromJson(response.data);
  }

  Future<UserResponse> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/profile/avatar', data: formData);
    return UserResponse.fromJson(response.data);
  }
}
