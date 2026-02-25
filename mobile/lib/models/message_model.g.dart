// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageCreate _$MessageCreateFromJson(Map<String, dynamic> json) =>
    MessageCreate(
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'NORMAL',
      pattern: json['pattern'] as Map<String, dynamic>?,
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MessageCreateToJson(MessageCreate instance) =>
    <String, dynamic>{
      'receiver_id': instance.receiverId,
      'content': instance.content,
      'message_type': instance.messageType,
      'pattern': instance.pattern,
      'waveform': instance.waveform,
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      id: (json['id'] as num).toInt(),
      senderBipupuId: json['sender_bipupu_id'] as String,
      receiverBipupuId: json['receiver_bipupu_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String,
      pattern: json['pattern'] as Map<String, dynamic>?,
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_bipupu_id': instance.senderBipupuId,
      'receiver_bipupu_id': instance.receiverBipupuId,
      'content': instance.content,
      'message_type': instance.messageType,
      'pattern': instance.pattern,
      'waveform': instance.waveform,
      'created_at': instance.createdAt.toIso8601String(),
    };

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

FavoriteCreate _$FavoriteCreateFromJson(Map<String, dynamic> json) =>
    FavoriteCreate(note: json['note'] as String?);

Map<String, dynamic> _$FavoriteCreateToJson(FavoriteCreate instance) =>
    <String, dynamic>{'note': instance.note};

FavoriteResponse _$FavoriteResponseFromJson(Map<String, dynamic> json) =>
    FavoriteResponse(
      id: (json['id'] as num).toInt(),
      messageId: (json['message_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FavoriteResponseToJson(FavoriteResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_id': instance.messageId,
      'user_id': instance.userId,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };

FavoriteListResponse _$FavoriteListResponseFromJson(
  Map<String, dynamic> json,
) => FavoriteListResponse(
  favorites: (json['favorites'] as List<dynamic>)
      .map((e) => FavoriteResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['page_size'] as num).toInt(),
);

Map<String, dynamic> _$FavoriteListResponseToJson(
  FavoriteListResponse instance,
) => <String, dynamic>{
  'favorites': instance.favorites,
  'total': instance.total,
  'page': instance.page,
  'page_size': instance.pageSize,
};
