// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'service_account_response.dart';

part 'service_account_list.g.dart';

/// 服务号列表响应
@JsonSerializable()
class ServiceAccountList {
  const ServiceAccountList({
    required this.items,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  });
  
  factory ServiceAccountList.fromJson(Map<String, Object?> json) => _$ServiceAccountListFromJson(json);
  
  final List<ServiceAccountResponse> items;
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$ServiceAccountListToJson(this);
}
