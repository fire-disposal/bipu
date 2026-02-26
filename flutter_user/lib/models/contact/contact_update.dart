import 'package:json_annotation/json_annotation.dart';

part 'contact_update.g.dart';

/// 更新联系人请求模型
@JsonSerializable()
class ContactUpdate {
  /// 联系人别名
  final String? alias;

  ContactUpdate({this.alias});

  factory ContactUpdate.fromJson(Map<String, dynamic> json) =>
      _$ContactUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ContactUpdateToJson(this);
}
