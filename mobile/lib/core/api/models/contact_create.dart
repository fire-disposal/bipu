// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'contact_create.g.dart';

/// 创建联系人请求
@JsonSerializable()
class ContactCreate {
  const ContactCreate({
    required this.contactId,
    this.alias,
  });
  
  factory ContactCreate.fromJson(Map<String, Object?> json) => _$ContactCreateFromJson(json);
  
  /// 联系人用户ID
  @JsonKey(name: 'contact_id')
  final String contactId;

  /// 备注名
  final String? alias;

  Map<String, Object?> toJson() => _$ContactCreateToJson(this);
}
