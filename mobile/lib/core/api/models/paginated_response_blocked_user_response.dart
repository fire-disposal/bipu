// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'blocked_user_response.dart';

part 'paginated_response_blocked_user_response.g.dart';

@JsonSerializable()
class PaginatedResponseBlockedUserResponse {
  const PaginatedResponseBlockedUserResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });
  
  factory PaginatedResponseBlockedUserResponse.fromJson(Map<String, Object?> json) => _$PaginatedResponseBlockedUserResponseFromJson(json);
  
  final List<BlockedUserResponse> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  Map<String, Object?> toJson() => _$PaginatedResponseBlockedUserResponseToJson(this);
}
