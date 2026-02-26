// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'contact_response.dart';

part 'contact_list_response.g.dart';

/// 联系人列表响应
@JsonSerializable()
class ContactListResponse {
  const ContactListResponse({
    required this.contacts,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  });
  
  factory ContactListResponse.fromJson(Map<String, Object?> json) => _$ContactListResponseFromJson(json);
  
  final List<ContactResponse> contacts;
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$ContactListResponseToJson(this);
}
