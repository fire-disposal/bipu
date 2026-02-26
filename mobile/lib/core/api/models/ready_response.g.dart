// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ready_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadyResponse _$ReadyResponseFromJson(Map<String, dynamic> json) =>
    ReadyResponse(
      status: json['status'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$ReadyResponseToJson(ReadyResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
    };
