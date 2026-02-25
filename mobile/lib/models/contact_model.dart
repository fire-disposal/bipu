import 'package:json_annotation/json_annotation.dart';

part 'contact_model.g.dart';

/// 联系人模型
@JsonSerializable()
class ContactResponse {
  /// 联系人ID
  final int id;

  /// 联系人Bipupu ID
  @JsonKey(name: 'contact_bipupu_id')
  final String contactBipupuId;

  /// 联系人用户名
  @JsonKey(name: 'contact_username')
  final String contactUsername;

  /// 联系人昵称
  @JsonKey(name: 'contact_nickname')
  final String? contactNickname;

  /// 备注名
  final String? alias;

  /// 创建时间
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  ContactResponse({
    required this.id,
    required this.contactBipupuId,
    required this.contactUsername,
    this.contactNickname,
    this.alias,
    required this.createdAt,
  });

  factory ContactResponse.fromJson(Map<String, dynamic> json) =>
      _$ContactResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ContactResponseToJson(this);

  /// 获取显示名称（优先使用备注，然后是昵称，最后是用户名）
  String get displayName {
    if (alias != null && alias!.isNotEmpty) {
      return alias!;
    }
    if (contactNickname != null && contactNickname!.isNotEmpty) {
      return contactNickname!;
    }
    return contactUsername;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contactBipupuId == other.contactBipupuId &&
          contactUsername == other.contactUsername &&
          contactNickname == other.contactNickname &&
          alias == other.alias &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      contactBipupuId.hashCode ^
      contactUsername.hashCode ^
      contactNickname.hashCode ^
      alias.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'ContactResponse(id: $id, contactBipupuId: $contactBipupuId, contactUsername: $contactUsername, contactNickname: $contactNickname, alias: $alias, createdAt: $createdAt)';
  }
}

/// 联系人创建请求
@JsonSerializable()
class ContactCreate {
  /// 联系人Bipupu ID
  @JsonKey(name: 'contact_bipupu_id')
  final String contactBipupuId;

  /// 备注名
  final String? remark;

  ContactCreate({required this.contactBipupuId, this.remark});

  factory ContactCreate.fromJson(Map<String, dynamic> json) =>
      _$ContactCreateFromJson(json);
  Map<String, dynamic> toJson() => _$ContactCreateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactCreate &&
          runtimeType == other.runtimeType &&
          contactBipupuId == other.contactBipupuId &&
          remark == other.remark;

  @override
  int get hashCode => contactBipupuId.hashCode ^ remark.hashCode;

  @override
  String toString() =>
      'ContactCreate(contactBipupuId: $contactBipupuId, remark: $remark)';
}

/// 联系人更新请求
@JsonSerializable()
class ContactUpdate {
  /// 备注名
  final String? remark;

  ContactUpdate({this.remark});

  factory ContactUpdate.fromJson(Map<String, dynamic> json) =>
      _$ContactUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$ContactUpdateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactUpdate &&
          runtimeType == other.runtimeType &&
          remark == other.remark;

  @override
  int get hashCode => remark.hashCode;

  @override
  String toString() => 'ContactUpdate(remark: $remark)';
}

/// 联系人列表响应
@JsonSerializable()
class ContactListResponse {
  /// 联系人列表
  final List<ContactResponse> contacts;

  /// 总数量
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  ContactListResponse({
    required this.contacts,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ContactListResponse.fromJson(Map<String, dynamic> json) =>
      _$ContactListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ContactListResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactListResponse &&
          runtimeType == other.runtimeType &&
          contacts == other.contacts &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      contacts.hashCode ^ total.hashCode ^ page.hashCode ^ pageSize.hashCode;

  @override
  String toString() {
    return 'ContactListResponse(contacts: $contacts, total: $total, page: $page, pageSize: $pageSize)';
  }
}
