import 'api.dart';
import '../models/user/user_response.dart';

class UserApi {
  final ApiClient _api;

  UserApi([ApiClient? client]) : _api = client ?? api;

  Future<UserResponse> getUserByBipupuId(String bipupuId) async {
    final data = await _api.get<Map<String, dynamic>>('/api/users/$bipupuId');
    return UserResponse.fromJson(data);
  }

  /// 更新推送时间设置
  Future<UserResponse> updatePushTime({required String fortuneTime}) async {
    final data = await _api.put<Map<String, dynamic>>(
      '/api/profile/push-time',
      data: {'fortune_time': fortuneTime},
    );
    return UserResponse.fromJson(data);
  }

  /// 更新时区设置
  Future<UserResponse> updateTimezone({required String timezone}) async {
    final data = await _api.put<Map<String, dynamic>>(
      '/api/profile/timezone',
      data: {'timezone': timezone},
    );
    return UserResponse.fromJson(data);
  }

  /// 获取推送设置信息
  Future<Map<String, dynamic>> getPushSettings() async {
    return await _api.get<Map<String, dynamic>>('/api/profile/push-settings');
  }
}
