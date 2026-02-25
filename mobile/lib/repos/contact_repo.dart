import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api/rest_client.dart';
import '../shared/models/contact_model.dart';

/// 极简联系人仓库 - 直接调用API
class ContactRepo {
  static ContactRepo get to => Get.find();

  late final RestClient _api;

  ContactRepo() {
    _api = RestClient(Dio());
  }

  /// 获取联系人列表
  Future<Map<String, dynamic>> getContacts({int? page, int? size}) async {
    try {
      final response = await _api.getContacts(page: page, size: size);

      if (response.response.statusCode == 200) {
        final contacts = (response.data as List)
            .map((json) => ContactResponse.fromJson(json))
            .toList();
        return {'success': true, 'data': contacts};
      } else {
        return {
          'success': false,
          'error': '获取联系人失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 添加联系人
  Future<Map<String, dynamic>> addContact(
    String bipupuId, {
    String? remark,
  }) async {
    try {
      final response = await _api.addContact({
        'contact_bipupu_id': bipupuId,
        if (remark != null) 'alias': remark,
      });

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '添加联系人失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 删除联系人
  Future<Map<String, dynamic>> deleteContact(String contactBipupuId) async {
    try {
      await _api.deleteContact(contactBipupuId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 更新联系人备注
  Future<Map<String, dynamic>> updateContact(
    String contactBipupuId,
    String remark,
  ) async {
    try {
      final response = await _api.updateContact(contactBipupuId, {
        'alias': remark,
      });

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '更新联系人失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 通过bipupu_id获取用户信息
  Future<Map<String, dynamic>> getUserByBipupuId(String bipupuId) async {
    try {
      final response = await _api.getUserByBipupuId(bipupuId);

      if (response.response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': '获取用户信息失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
