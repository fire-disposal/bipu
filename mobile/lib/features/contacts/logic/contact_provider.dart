import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/contact_model.dart';

/// 联系人状态
enum ContactStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 已加载
  loaded,

  /// 错误
  error,
}

/// 联系人列表状态
class ContactListState {
  final ContactStatus status;
  final List<ContactResponse> contacts;
  final int page;
  final int total;
  final bool hasMore;
  final String? error;

  const ContactListState({
    this.status = ContactStatus.initial,
    this.contacts = const [],
    this.page = 1,
    this.total = 0,
    this.hasMore = true,
    this.error,
  });

  ContactListState copyWith({
    ContactStatus? status,
    List<ContactResponse>? contacts,
    int? page,
    int? total,
    bool? hasMore,
    String? error,
  }) {
    return ContactListState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactListState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          contacts == other.contacts &&
          page == other.page &&
          total == other.total &&
          hasMore == other.hasMore &&
          error == other.error;

  @override
  int get hashCode =>
      status.hashCode ^
      contacts.hashCode ^
      page.hashCode ^
      total.hashCode ^
      hasMore.hashCode ^
      error.hashCode;

  @override
  String toString() {
    return 'ContactListState(status: $status, contacts: ${contacts.length}, page: $page, total: $total, hasMore: $hasMore, error: $error)';
  }
}

/// 联系人列表提供者
final contactsProvider = NotifierProvider<ContactsNotifier, ContactListState>(
  () => ContactsNotifier(),
);

class ContactsNotifier extends Notifier<ContactListState> {
  @override
  ContactListState build() {
    return const ContactListState();
  }

  /// 加载联系人列表
  Future<void> loadContacts({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(status: ContactStatus.loading, page: 1);
      } else {
        state = state.copyWith(status: ContactStatus.loading);
      }

      final restClient = ref.read(restClientProvider);
      final page = refresh ? 1 : state.page;
      final pageSize = 20;

      final response = await restClient.getContacts(page: page, size: pageSize);

      if (response.response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final contactList = ContactListResponse.fromJson(data);

        final contacts = refresh
            ? contactList.contacts
            : [...state.contacts, ...contactList.contacts];

        state = ContactListState(
          status: ContactStatus.loaded,
          contacts: contacts,
          page: contactList.page + 1,
          total: contactList.total,
          hasMore: contacts.length < contactList.total,
          error: null,
        );
      } else {
        state = state.copyWith(
          status: ContactStatus.error,
          error: '加载失败: ${response.response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[Contacts] 加载联系人失败：$e');
      state = state.copyWith(status: ContactStatus.error, error: '加载失败: $e');
    }
  }

  /// 加载更多联系人
  Future<void> loadMore() async {
    if (state.status == ContactStatus.loading || !state.hasMore) {
      return;
    }

    await loadContacts(refresh: false);
  }

  /// 刷新联系人列表
  Future<void> refresh() async {
    await loadContacts(refresh: true);
  }

  /// 添加联系人
  Future<bool> addContact(String contactBipupuId, {String? remark}) async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.addContact({
        'contact_bipupu_id': contactBipupuId,
        if (remark != null) 'remark': remark,
      });

      if (response.response.statusCode == 200) {
        debugPrint('[Contacts] 添加联系人成功: $contactBipupuId');
        // 刷新列表
        await refresh();
        return true;
      } else {
        debugPrint('[Contacts] 添加联系人失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Contacts] 添加联系人异常：$e');
      return false;
    }
  }

  /// 删除联系人
  Future<bool> deleteContact(String contactBipupuId) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.deleteContact(contactBipupuId);

      debugPrint('[Contacts] 删除联系人成功: $contactBipupuId');

      // 从本地状态中移除
      final contacts = state.contacts
          .where((contact) => contact.contactBipupuId != contactBipupuId)
          .toList();

      state = state.copyWith(contacts: contacts);
      return true;
    } catch (e) {
      debugPrint('[Contacts] 删除联系人失败：$e');
      return false;
    }
  }

  /// 更新联系人备注
  Future<bool> updateContactRemark(
    String contactBipupuId,
    String remark,
  ) async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.updateContact(contactBipupuId, {
        'remark': remark,
      });

      if (response.response.statusCode == 200) {
        debugPrint('[Contacts] 更新联系人备注成功: $contactBipupuId -> $remark');

        // 更新本地状态
        final contacts = state.contacts.map((contact) {
          if (contact.contactBipupuId == contactBipupuId) {
            return ContactResponse(
              id: contact.id,
              contactBipupuId: contact.contactBipupuId,
              username: contact.username,
              nickname: contact.nickname,
              remark: remark,
              avatarUrl: contact.avatarUrl,
              isBlocked: contact.isBlocked,
              createdAt: contact.createdAt,
              updatedAt: contact.updatedAt,
            );
          }
          return contact;
        }).toList();

        state = state.copyWith(contacts: contacts);
        return true;
      } else {
        debugPrint('[Contacts] 更新联系人备注失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Contacts] 更新联系人备注异常：$e');
      return false;
    }
  }

  /// 搜索联系人
  List<ContactResponse> searchContacts(String query) {
    if (query.isEmpty) {
      return state.contacts;
    }

    final lowercaseQuery = query.toLowerCase();
    return state.contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(lowercaseQuery) ||
          contact.username.toLowerCase().contains(lowercaseQuery) ||
          contact.contactBipupuId.toLowerCase().contains(lowercaseQuery) ||
          (contact.remark?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// 根据Bipupu ID获取联系人
  ContactResponse? getContactByBipupuId(String bipupuId) {
    try {
      return state.contacts.firstWhere(
        (contact) => contact.contactBipupuId == bipupuId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 清除错误状态
  void clearError() {
    if (state.status == ContactStatus.error) {
      state = state.copyWith(status: ContactStatus.loaded, error: null);
    }
  }
}

/// 联系人控制器
class ContactController {
  final Ref ref;

  ContactController({required this.ref});

  /// 获取联系人Notifier
  ContactsNotifier get _contactsNotifier => ref.read(contactsProvider.notifier);

  /// 加载联系人列表
  Future<void> loadContacts({bool refresh = false}) async {
    await _contactsNotifier.loadContacts(refresh: refresh);
  }

  /// 加载更多联系人
  Future<void> loadMore() async {
    await _contactsNotifier.loadMore();
  }

  /// 刷新联系人列表
  Future<void> refresh() async {
    await _contactsNotifier.refresh();
  }

  /// 添加联系人
  Future<bool> addContact(String contactBipupuId, {String? remark}) async {
    return await _contactsNotifier.addContact(contactBipupuId, remark: remark);
  }

  /// 删除联系人
  Future<bool> deleteContact(String contactBipupuId) async {
    return await _contactsNotifier.deleteContact(contactBipupuId);
  }

  /// 更新联系人备注
  Future<bool> updateContactRemark(
    String contactBipupuId,
    String remark,
  ) async {
    return await _contactsNotifier.updateContactRemark(contactBipupuId, remark);
  }

  /// 搜索联系人
  List<ContactResponse> searchContacts(String query) {
    return _contactsNotifier.searchContacts(query);
  }

  /// 根据Bipupu ID获取联系人
  ContactResponse? getContactByBipupuId(String bipupuId) {
    return _contactsNotifier.getContactByBipupuId(bipupuId);
  }

  /// 清除错误状态
  void clearError() {
    _contactsNotifier.clearError();
  }
}

/// 联系人控制器提供者
final contactControllerProvider = Provider<ContactController>((ref) {
  return ContactController(ref: ref);
});
