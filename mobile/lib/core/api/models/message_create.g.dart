// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageCreate _$MessageCreateFromJson(Map<String, dynamic> json) =>
    MessageCreate(
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      pattern: json['pattern'],
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      messageType: json['message_type'] == null
          ? MessageType.normal
          : MessageType.fromJson(json['message_type'] as String),
    );

Map<String, dynamic> _$MessageCreateToJson(MessageCreate instance) =>
    <String, dynamic>{
      'receiver_id': instance.receiverId,
      'content': instance.content,
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'pattern': instance.pattern,
      'waveform': instance.waveform,
    };

const _$MessageTypeEnumMap = {
  MessageType.normal: 'NORMAL',
  MessageType.voice: 'VOICE',
  MessageType.system: 'SYSTEM',
  MessageType.$unknown: r'$unknown',
};
