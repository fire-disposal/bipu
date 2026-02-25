import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api/rest_client.dart';
import '../shared/models/block_model.dart';

/// 极简黑名单仓库 - 直接调用API
class BlockRepo {
  static BlockRepo get to => Get.find();

  late final RestClient _api;

  BlockRepo() {
    _api = RestClient(Dio());
  }

  /// 获取黑名单列表
  Future<Map<String, dynamic>> getBlockedUsers({int? page, int? size}) async {
    try {
      final response = await _api.getBlockedUsers(page: page, size: size);

      if (response.response.statusCode == 200) {
        final blocks = (response.data as List)
            .map((json) => BlockedUserResponse.fromJson(json))
            .toList();
        return {'success': true, 'data': blocks};
      } else {
        return {
          'success': false,
          'error': '获取黑名单失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 拉黑用户
  Future<Map<String, dynamic>> blockUser(String bipupuId) async {
    try {
      final response = await _api.blockUser({'bipupu_id': bipupuId});

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '拉黑用户失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 取消拉黑用户
  Future<Map<String, dynamic>> unblockUser(String bipupuId) async {
    try {
      final response = await _api.unblockUser(bipupuId);

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '取消拉黑失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
