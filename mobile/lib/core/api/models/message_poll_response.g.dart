// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_poll_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessagePollResponse _$MessagePollResponseFromJson(Map<String, dynamic> json) =>
    MessagePollResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool? ?? false,
    );

Map<String, dynamic> _$MessagePollResponseToJson(
  MessagePollResponse instance,
) => <String, dynamic>{
  'messages': instance.messages,
  'has_more': instance.hasMore,
};
