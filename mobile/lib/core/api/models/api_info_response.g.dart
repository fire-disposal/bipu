// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_info_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiInfoResponse _$ApiInfoResponseFromJson(Map<String, dynamic> json) =>
    ApiInfoResponse(
      message: json['message'] as String,
      version: json['version'] as String,
      project: json['project'] as String,
      docsUrl: json['docs_url'] as String,
      redocUrl: json['redoc_url'] as String,
      adminUrl: json['admin_url'] as String,
    );

Map<String, dynamic> _$ApiInfoResponseToJson(ApiInfoResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'version': instance.version,
      'project': instance.project,
      'docs_url': instance.docsUrl,
      'redoc_url': instance.redocUrl,
      'admin_url': instance.adminUrl,
    };
