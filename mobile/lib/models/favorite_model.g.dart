// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteCreate _$FavoriteCreateFromJson(Map<String, dynamic> json) =>
    FavoriteCreate(note: json['note'] as String?);

Map<String, dynamic> _$FavoriteCreateToJson(FavoriteCreate instance) =>
    <String, dynamic>{'note': instance.note};

FavoriteResponse _$FavoriteResponseFromJson(Map<String, dynamic> json) =>
    FavoriteResponse(
      id: (json['id'] as num).toInt(),
      messageId: (json['messageId'] as num).toInt(),
      userId: json['userId'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FavoriteResponseToJson(FavoriteResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'userId': instance.userId,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };

FavoriteListResponse _$FavoriteListResponseFromJson(
  Map<String, dynamic> json,
) => FavoriteListResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => FavoriteResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['page_size'] as num).toInt(),
  totalPages: (json['total_pages'] as num).toInt(),
);

Map<String, dynamic> _$FavoriteListResponseToJson(
  FavoriteListResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'page_size': instance.pageSize,
  'total_pages': instance.totalPages,
};

FavoriteWithMessageResponse _$FavoriteWithMessageResponseFromJson(
  Map<String, dynamic> json,
) => FavoriteWithMessageResponse(
  favorite: FavoriteResponse.fromJson(json['favorite'] as Map<String, dynamic>),
  message: MessageResponse.fromJson(json['message'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FavoriteWithMessageResponseToJson(
  FavoriteWithMessageResponse instance,
) => <String, dynamic>{
  'favorite': instance.favorite,
  'message': instance.message,
};

FavoriteStats _$FavoriteStatsFromJson(Map<String, dynamic> json) =>
    FavoriteStats(
      total: (json['total'] as num).toInt(),
      today: (json['today'] as num).toInt(),
      thisWeek: (json['thisWeek'] as num).toInt(),
      thisMonth: (json['thisMonth'] as num).toInt(),
    );

Map<String, dynamic> _$FavoriteStatsToJson(FavoriteStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'today': instance.today,
      'thisWeek': instance.thisWeek,
      'thisMonth': instance.thisMonth,
    };
