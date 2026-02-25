// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    HealthResponse(
      status: json['status'] as String,
      timestamp: json['timestamp'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$HealthResponseToJson(HealthResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
      'version': instance.version,
    };

ReadyResponse _$ReadyResponseFromJson(Map<String, dynamic> json) =>
    ReadyResponse(
      status: json['status'] as String,
      services: (json['services'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$ReadyResponseToJson(ReadyResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'services': instance.services,
      'timestamp': instance.timestamp,
    };

LiveResponse _$LiveResponseFromJson(Map<String, dynamic> json) => LiveResponse(
  status: json['status'] as String,
  timestamp: json['timestamp'] as String,
);

Map<String, dynamic> _$LiveResponseToJson(LiveResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
    };

ApiInfoResponse _$ApiInfoResponseFromJson(Map<String, dynamic> json) =>
    ApiInfoResponse(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      documentation: json['documentation'] as String,
      endpoints: Map<String, String>.from(json['endpoints'] as Map),
    );

Map<String, dynamic> _$ApiInfoResponseToJson(ApiInfoResponse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
      'documentation': instance.documentation,
      'endpoints': instance.endpoints,
    };

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(detail: json['detail'] as String);

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{'detail': instance.detail};

ValidationError _$ValidationErrorFromJson(Map<String, dynamic> json) =>
    ValidationError(
      loc: (json['loc'] as List<dynamic>).map((e) => e as String).toList(),
      msg: json['msg'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      'loc': instance.loc,
      'msg': instance.msg,
      'type': instance.type,
    };

HTTPValidationError _$HTTPValidationErrorFromJson(Map<String, dynamic> json) =>
    HTTPValidationError(
      detail: (json['detail'] as List<dynamic>)
          .map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HTTPValidationErrorToJson(
  HTTPValidationError instance,
) => <String, dynamic>{'detail': instance.detail};

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PaginatedResponse<T>(
  items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'items': instance.items.map(toJsonT).toList(),
  'total': instance.total,
  'page': instance.page,
  'pageSize': instance.pageSize,
  'totalPages': instance.totalPages,
};

SuccessResponse<T> _$SuccessResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => SuccessResponse<T>(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
);

Map<String, dynamic> _$SuccessResponseToJson<T>(
  SuccessResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
