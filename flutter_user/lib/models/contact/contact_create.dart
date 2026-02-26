import 'package:json_annotation/json_annotation.dart';

part 'contact_create.g.dart';

/// 创建联系人请求模型
@JsonSerializable()
class ContactCreate {
  /// 联系人ID
  @JsonKey(name: 'contact_id')
  final String contactId;

  /// 联系人别名
  final String? alias;

  ContactCreate({required this.contactId, this.alias});

  factory ContactCreate.fromJson(Map<String, dynamic> json) =>
      _$ContactCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ContactCreateToJson(this);
}
