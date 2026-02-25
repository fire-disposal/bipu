import 'package:get/get.dart';
import '../services/contact_service.dart';
import '../models/contact_model.dart';

/// 联系人控制器 - 使用新的ContactService
class ContactController extends GetxController {
  static ContactController get to => Get.find();

  // 依赖服务
  final ContactService _contact = ContactService.instance;

  // 计算属性 - 直接暴露服务的状态
  List<ContactResponse> get contacts => _contact.contacts;
  bool get isLoading => _contact.isLoading.value;
  String get error => _contact.error.value;

  /// 加载联系人列表
  Future<void> loadContacts({int? page, int? size}) async {
    final response = await _contact.getContacts(page: page, size: size);

    if (response.success) {
      // 联系人加载成功，状态已由ContactService更新
    } else if (response.error != null) {
      // 错误处理已由ContactService完成
    }
  }

  /// 添加联系人
  Future<void> addContact({
    required String contactBipupuId,
    String? remark,
  }) async {
    final response = await _contact.addContact(
      contactBipupuId: contactBipupuId,
      remark: remark,
    );

    if (response.success) {
      // 联系人添加成功，状态已由ContactService更新
    } else if (response.error != null) {
      // 错误处理已由ContactService完成
    }
  }

  /// 删除联系人
  Future<void> deleteContact(String contactBipupuId) async {
    final response = await _contact.deleteContact(contactBipupuId);

    if (response.success) {
      // 联系人删除成功，状态已由ContactService更新
    } else if (response.error != null) {
      // 错误处理已由ContactService完成
    }
  }

  /// 更新联系人备注
  Future<void> updateContactRemark({
    required String contactBipupuId,
    required String remark,
  }) async {
    final response = await _contact.updateContact(
      contactBipupuId: contactBipupuId,
      remark: remark,
    );

    if (response.success) {
      // 备注更新成功，状态已由ContactService更新
    } else if (response.error != null) {
      // 错误处理已由ContactService完成
    }
  }

  /// 根据Bipupu ID查找联系人
  ContactResponse? findContactByBipupuId(String bipupuId) {
    return _contact.findContactByBipupuId(bipupuId);
  }

  /// 检查联系人是否存在
  bool contactExists(String bipupuId) {
    return _contact.findContactByBipupuId(bipupuId) != null;
  }

  /// 获取联系人统计
  Map<String, int> getContactStats() {
    return {'total': contacts.length};
  }

  /// 清空错误信息
  void clearError() {
    _contact.clearError();
  }

  /// 清空联系人列表
  void clearAll() {
    _contact.clearAll();
  }

  /// 初始化联系人数据
  Future<void> initialize() async {
    if (contacts.isEmpty) {
      await loadContacts();
    }
  }

  /// 获取活跃联系人
  List<ContactResponse> get activeContacts {
    return contacts;
  }

  /// 获取联系人ID列表
  List<String> get contactBipupuIds {
    return contacts.map((contact) => contact.contactBipupuId).toList();
  }

  /// 根据备注搜索联系人
  List<ContactResponse> searchContactsByRemark(String keyword) {
    if (keyword.isEmpty) return contacts;

    final lowerKeyword = keyword.toLowerCase();
    return contacts
        .where(
          (contact) =>
              contact.alias != null &&
              contact.alias!.toLowerCase().contains(lowerKeyword),
        )
        .toList();
  }

  /// 根据用户名搜索联系人
  List<ContactResponse> searchContactsByUsername(String keyword) {
    if (keyword.isEmpty) return contacts;

    final lowerKeyword = keyword.toLowerCase();
    return contacts
        .where(
          (contact) =>
              contact.contactUsername.toLowerCase().contains(lowerKeyword),
        )
        .toList();
  }

  /// 根据昵称搜索联系人
  List<ContactResponse> searchContactsByNickname(String keyword) {
    if (keyword.isEmpty) return contacts;

    final lowerKeyword = keyword.toLowerCase();
    return contacts
        .where(
          (contact) =>
              contact.contactNickname != null &&
              contact.contactNickname!.toLowerCase().contains(lowerKeyword),
        )
        .toList();
  }

  /// 获取最近添加的联系人
  List<ContactResponse> get recentlyAddedContacts {
    return List.from(contacts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取最近添加的联系人（按创建时间排序）
  List<ContactResponse> get recentlyAddedContactsSorted {
    return List.from(contacts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
