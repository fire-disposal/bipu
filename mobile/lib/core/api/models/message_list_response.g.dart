// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageListResponse _$MessageListResponseFromJson(Map<String, dynamic> json) =>
    MessageListResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
    );

Map<String, dynamic> _$MessageListResponseToJson(
  MessageListResponse instance,
) => <String, dynamic>{
  'messages': instance.messages,
  'total': instance.total,
  'page': instance.page,
  'page_size': instance.pageSize,
};
