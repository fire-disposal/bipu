// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      id: (json['id'] as num).toInt(),
      senderBipupuId: json['sender_bipupu_id'] as String,
      receiverBipupuId: json['receiver_bipupu_id'] as String,
      content: json['content'] as String,
      messageType: MessageType.fromJson(json['message_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      pattern: json['pattern'],
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_bipupu_id': instance.senderBipupuId,
      'receiver_bipupu_id': instance.receiverBipupuId,
      'content': instance.content,
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'pattern': instance.pattern,
      'waveform': instance.waveform,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$MessageTypeEnumMap = {
  MessageType.normal: 'NORMAL',
  MessageType.voice: 'VOICE',
  MessageType.system: 'SYSTEM',
  MessageType.$unknown: r'$unknown',
};
