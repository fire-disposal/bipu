// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'contact_update.g.dart';

/// 更新联系人请求
@JsonSerializable()
class ContactUpdate {
  const ContactUpdate({
    this.alias,
  });
  
  factory ContactUpdate.fromJson(Map<String, Object?> json) => _$ContactUpdateFromJson(json);
  
  /// 备注名
  final String? alias;

  Map<String, Object?> toJson() => _$ContactUpdateToJson(this);
}
