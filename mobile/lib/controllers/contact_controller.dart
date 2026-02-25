import 'package:get/get.dart';
import '../repos/contact_repo.dart';
import '../shared/models/contact_model.dart';

/// 极简联系人控制器 - GetX风格
class ContactController extends GetxController {
  static ContactController get to => Get.find();

  // 状态
  final contacts = <ContactResponse>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final selectedContact = Rxn<ContactResponse>();

  // 仓库
  final ContactRepo _repo = ContactRepo();

  /// 加载联系人列表
  Future<void> loadContacts({int? page, int? size}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.getContacts(page: page, size: size);

      if (result['success'] == true) {
        contacts.value = result['data'] as List<ContactResponse>;
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '加载联系人失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 添加联系人
  Future<void> addContact(String bipupuId, {String? remark}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.addContact(bipupuId, remark: remark);

      if (result['success'] == true) {
        Get.snackbar('成功', '联系人添加成功');
        await loadContacts(); // 刷新列表
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '添加联系人失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除联系人
  Future<void> deleteContact(String contactBipupuId) async {
    try {
      final result = await _repo.deleteContact(contactBipupuId);

      if (result['success'] == true) {
        Get.snackbar('成功', '联系人已删除');
        contacts.removeWhere(
          (contact) => contact.contactBipupuId == contactBipupuId,
        );
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '删除联系人失败: $e');
    }
  }

  /// 更新联系人备注
  Future<void> updateContactRemark(
    String contactBipupuId,
    String remark,
  ) async {
    try {
      final result = await _repo.updateContact(contactBipupuId, remark);

      if (result['success'] == true) {
        Get.snackbar('成功', '备注已更新');

        // 更新本地数据
        final index = contacts.indexWhere(
          (c) => c.contactBipupuId == contactBipupuId,
        );
        if (index != -1) {
          final contact = contacts[index];
          contacts[index] = ContactResponse(
            id: contact.id,
            contactBipupuId: contact.contactBipupuId,
            contactUsername: contact.contactUsername,
            contactNickname: contact.contactNickname,
            alias: remark,
            createdAt: contact.createdAt,
          );
        }
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '更新备注失败: $e');
    }
  }

  /// 搜索用户
  Future<Map<String, dynamic>?> searchUser(String bipupuId) async {
    try {
      final result = await _repo.getUserByBipupuId(bipupuId);

      if (result['success'] == true) {
        return result['data'] as Map<String, dynamic>;
      } else {
        Get.snackbar('错误', result['error'] as String);
        return null;
      }
    } catch (e) {
      Get.snackbar('错误', '搜索用户失败: $e');
      return null;
    }
  }

  /// 选择联系人
  void selectContact(ContactResponse contact) {
    selectedContact.value = contact;
  }

  /// 清除选择
  void clearSelection() {
    selectedContact.value = null;
  }

  /// 获取联系人统计
  Map<String, int> getContactStats() {
    return {
      'total': contacts.length,
      'recent': contacts.length, // 简化：全部视为最近
    };
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    loadContacts();
  }
}
