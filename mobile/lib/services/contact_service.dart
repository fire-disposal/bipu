import 'package:get/get.dart';
import 'base_service.dart';
import '../models/contact_model.dart';

/// 联系人服务 - 效仿AuthService模式
class ContactService extends BaseService {
  static ContactService get instance => Get.find();

  final contacts = <ContactResponse>[].obs;
  final isLoading = false.obs;
  final RxString error = ''.obs;

  /// 获取联系人列表
  Future<ServiceResponse<List<ContactResponse>>> getContacts({
    int? page,
    int? size,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/contacts',
      query: {
        if (page != null) 'page': page.toString(),
        if (size != null) 'size': size.toString(),
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final contactList = response.data!
          .map((json) => ContactResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      contacts.assignAll(contactList);
      return ServiceResponse.success(contactList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取联系人失败', ServiceErrorType.unknown),
    );
  }

  /// 添加联系人
  Future<ServiceResponse<ContactResponse>> addContact({
    required String contactBipupuId,
    String? remark,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await post<ContactResponse>(
      '/api/contacts',
      data: {
        'contact_bipupu_id': contactBipupuId,
        if (remark != null) 'remark': remark,
      },
      fromJson: (json) => ContactResponse.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      contacts.add(response.data!);
      Get.snackbar('成功', '联系人添加成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 删除联系人
  Future<ServiceResponse<void>> deleteContact(String contactBipupuId) async {
    isLoading.value = true;
    error.value = '';

    final response = await delete<void>('/api/contacts/$contactBipupuId');

    isLoading.value = false;

    if (response.success) {
      contacts.removeWhere(
        (contact) => contact.contactBipupuId == contactBipupuId,
      );
      Get.snackbar('成功', '联系人已删除', duration: const Duration(seconds: 2));
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 更新联系人备注
  Future<ServiceResponse<ContactResponse>> updateContact({
    required String contactBipupuId,
    required String remark,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await put<ContactResponse>(
      '/api/contacts/$contactBipupuId',
      data: {'remark': remark},
      fromJson: (json) => ContactResponse.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final index = contacts.indexWhere(
        (c) => c.contactBipupuId == contactBipupuId,
      );
      if (index != -1) {
        contacts[index] = response.data!;
      }
      Get.snackbar('成功', '备注更新成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 根据Bipupu ID查找联系人
  ContactResponse? findContactByBipupuId(String bipupuId) {
    return contacts.firstWhereOrNull(
      (contact) => contact.contactBipupuId == bipupuId,
    );
  }

  /// 检查联系人是否存在
  bool contactExists(String bipupuId) {
    return findContactByBipupuId(bipupuId) != null;
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 清空联系人列表
  void clearAll() {
    contacts.clear();
    error.value = '';
  }

  /// 初始化联系人数据
  Future<void> initialize() async {
    if (contacts.isEmpty) {
      await getContacts();
    }
  }

  /// 获取联系人ID列表
  List<String> get contactBipupuIds {
    return contacts.map((contact) => contact.contactBipupuId).toList();
  }

  /// 获取联系人显示名称列表
  List<String> get contactDisplayNames {
    return contacts.map((contact) => contact.displayName).toList();
  }

  /// 获取最近添加的联系人
  List<ContactResponse> get recentlyAddedContacts {
    return List.from(contacts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 根据备注搜索联系人
  List<ContactResponse> searchContactsByAlias(String keyword) {
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

  /// 获取联系人统计
  Map<String, int> getContactStats() {
    return {
      'total': contacts.length,
      'withAlias': contacts
          .where(
            (contact) => contact.alias != null && contact.alias!.isNotEmpty,
          )
          .length,
      'withoutAlias': contacts
          .where((contact) => contact.alias == null || contact.alias!.isEmpty)
          .length,
    };
  }
}
