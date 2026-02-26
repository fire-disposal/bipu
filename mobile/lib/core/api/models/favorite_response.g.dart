// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteResponse _$FavoriteResponseFromJson(Map<String, dynamic> json) =>
    FavoriteResponse(
      id: (json['id'] as num).toInt(),
      messageId: (json['message_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      messageContent: json['message_content'] as String,
      messageSender: json['message_sender'] as String,
      messageCreatedAt: DateTime.parse(json['message_created_at'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$FavoriteResponseToJson(FavoriteResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_id': instance.messageId,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
      'message_content': instance.messageContent,
      'message_sender': instance.messageSender,
      'message_created_at': instance.messageCreatedAt.toIso8601String(),
    };
