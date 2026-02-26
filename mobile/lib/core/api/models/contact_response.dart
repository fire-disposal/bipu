// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'contact_response.g.dart';

/// 联系人响应
@JsonSerializable()
class ContactResponse {
  const ContactResponse({
    required this.id,
    required this.contactId,
    required this.contactUsername,
    required this.createdAt,
    this.contactNickname,
    this.alias,
  });
  
  factory ContactResponse.fromJson(Map<String, Object?> json) => _$ContactResponseFromJson(json);
  
  final int id;

  /// 联系人用户ID
  @JsonKey(name: 'contact_id')
  final String contactId;

  /// 联系人用户名
  @JsonKey(name: 'contact_username')
  final String contactUsername;

  /// 联系人昵称
  @JsonKey(name: 'contact_nickname')
  final String? contactNickname;

  /// 备注名
  final String? alias;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$ContactResponseToJson(this);
}
