// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_response_blocked_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedResponseBlockedUserResponse
_$PaginatedResponseBlockedUserResponseFromJson(Map<String, dynamic> json) =>
    PaginatedResponseBlockedUserResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => BlockedUserResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedResponseBlockedUserResponseToJson(
  PaginatedResponseBlockedUserResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'size': instance.size,
  'pages': instance.pages,
};
