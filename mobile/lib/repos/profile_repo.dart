import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../api/rest_client.dart';

/// 极简个人资料仓库 - 直接调用API
class ProfileRepo {
  static ProfileRepo get to => Get.find();

  late final RestClient _api;

  ProfileRepo() {
    _api = RestClient(dio.Dio());
  }

  /// 获取用户详细资料
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _api.getUserProfile();

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '获取用户资料失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 更新用户信息
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.updateUserProfile(data);

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '更新用户资料失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 更新密码
  Future<Map<String, dynamic>> updatePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _api.updatePassword({
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '更新密码失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 更新时区
  Future<Map<String, dynamic>> updateTimezone(String timezone) async {
    try {
      final response = await _api.updateTimezone({'timezone': timezone});

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '更新时区失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取推送设置
  Future<Map<String, dynamic>> getPushSettings() async {
    try {
      final response = await _api.getPushSettings();

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '获取推送设置失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 上传头像
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    try {
      final file = await dio.MultipartFile.fromFile(
        filePath,
        filename: 'avatar.jpg',
      );
      final response = await _api.uploadAvatar(file);

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '上传头像失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
