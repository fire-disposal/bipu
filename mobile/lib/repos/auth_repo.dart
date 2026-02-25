import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api/rest_client.dart';

/// 极简认证仓库 - 直接调用API
class AuthRepo {
  static AuthRepo get to => Get.find();

  late final RestClient _api;

  AuthRepo() {
    _api = RestClient(Dio());
  }

  /// 登录
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.login({
        'username': username,
        'password': password,
      });

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '登录失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 注册
  Future<Map<String, dynamic>> register(
    String username,
    String password, {
    String? nickname,
  }) async {
    try {
      final response = await _api.register({
        'username': username,
        'password': password,
        if (nickname != null) 'nickname': nickname,
      });

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '注册失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取当前用户
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.getCurrentUser();

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '获取用户失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 登出
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _api.logout();

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '登出失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 刷新token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _api.refreshToken({'refresh_token': refreshToken});

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '刷新token失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
