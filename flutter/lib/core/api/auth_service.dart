import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_config.dart';

/// 统一管理JWT的认证服务
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  final _storage = const FlutterSecureStorage();
  String? _jwt;
  Map<String, dynamic>? _user;

  String? get token => _jwt;
  Map<String, dynamic>? get user => _user;

  /// 初始化，尝试从本地加载token
  Future<void> initialize() async {
    _jwt = await _storage.read(key: 'jwt_token');
    final userStr = await _storage.read(key: 'user_info');
    if (userStr != null) {
      _user = jsonDecode(userStr);
    }
  }

  /// 登录
  Future<bool> login(
    String username,
    String password, {
    bool adminOnly = false,
  }) async {
    final dio = Dio();
    final config = AppConfig();
    try {
      final resp = await dio.post(
        '${config.baseUrl}/users/login',
        data: {'username': username, 'password': password},
      );
      if (resp.statusCode == 200 && resp.data['access_token'] != null) {
        _jwt = resp.data['access_token'];
        await _storage.write(key: 'jwt_token', value: _jwt);
        // 获取用户信息
        final userResp = await dio.get(
          '${config.baseUrl}/users/me',
          options: Options(headers: {'Authorization': 'Bearer $_jwt'}),
        );
        if (userResp.statusCode == 200) {
          _user = userResp.data;
          await _storage.write(key: 'user_info', value: jsonEncode(_user));
          // 管理端校验
          if (adminOnly &&
              (_user?['is_superuser'] != true && _user?['role'] != 'admin')) {
            await logout();
            throw Exception('非管理员账号，禁止登录管理端');
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  /// 注册
  Future<bool> register(String email, String password, String nickname) async {
    final dio = Dio();
    final config = AppConfig();
    try {
      final resp = await dio.post(
        '${config.baseUrl}/users/register',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname,
          'username': email,
        },
      );
      if (resp.statusCode == 200 && resp.data['id'] != null) {
        // 自动登录
        return await login(email, password);
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    _jwt = null;
    _user = null;
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_info');
  }

  /// 获取当前token
  Future<String?> getToken() async {
    if (_jwt != null) return _jwt;
    _jwt = await _storage.read(key: 'jwt_token');
    return _jwt;
  }

  /// 是否已登录
  bool get isAuthenticated => _jwt != null && _user != null;

  /// 是否管理员
  bool get isAdmin =>
      _user?['is_superuser'] == true || _user?['role'] == 'admin';
}
