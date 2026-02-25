import 'package:json_annotation/json_annotation.dart';

part 'system_model.g.dart';

/// 健康检查响应
@JsonSerializable()
class HealthResponse {
  final String status;
  final String timestamp;
  final String version;

  HealthResponse({
    required this.status,
    required this.timestamp,
    required this.version,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$HealthResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthResponse &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          timestamp == other.timestamp &&
          version == other.version;

  @override
  int get hashCode => status.hashCode ^ timestamp.hashCode ^ version.hashCode;

  @override
  String toString() =>
      'HealthResponse(status: $status, timestamp: $timestamp, version: $version)';
}

/// 就绪检查响应
@JsonSerializable()
class ReadyResponse {
  final String status;
  final List<String> services;
  final String timestamp;

  ReadyResponse({
    required this.status,
    required this.services,
    required this.timestamp,
  });

  factory ReadyResponse.fromJson(Map<String, dynamic> json) =>
      _$ReadyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReadyResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadyResponse &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          services == other.services &&
          timestamp == other.timestamp;

  @override
  int get hashCode => status.hashCode ^ services.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'ReadyResponse(status: $status, services: $services, timestamp: $timestamp)';
}

/// 存活检查响应
@JsonSerializable()
class LiveResponse {
  final String status;
  final String timestamp;

  LiveResponse({required this.status, required this.timestamp});

  factory LiveResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LiveResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveResponse &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          timestamp == other.timestamp;

  @override
  int get hashCode => status.hashCode ^ timestamp.hashCode;

  @override
  String toString() => 'LiveResponse(status: $status, timestamp: $timestamp)';
}

/// API信息响应
@JsonSerializable()
class ApiInfoResponse {
  final String name;
  final String version;
  final String description;
  final String documentation;
  final Map<String, String> endpoints;

  ApiInfoResponse({
    required this.name,
    required this.version,
    required this.description,
    required this.documentation,
    required this.endpoints,
  });

  factory ApiInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiInfoResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiInfoResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiInfoResponse &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          version == other.version &&
          description == other.description &&
          documentation == other.documentation &&
          endpoints == other.endpoints;

  @override
  int get hashCode =>
      name.hashCode ^
      version.hashCode ^
      description.hashCode ^
      documentation.hashCode ^
      endpoints.hashCode;

  @override
  String toString() =>
      'ApiInfoResponse(name: $name, version: $version, description: $description, documentation: $documentation, endpoints: $endpoints)';
}

/// 错误响应
@JsonSerializable()
class ErrorResponse {
  final String detail;

  ErrorResponse({required this.detail});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorResponse &&
          runtimeType == other.runtimeType &&
          detail == other.detail;

  @override
  int get hashCode => detail.hashCode;

  @override
  String toString() => 'ErrorResponse(detail: $detail)';
}

/// 验证错误详情
@JsonSerializable()
class ValidationError {
  final List<String> loc;
  final String msg;
  final String type;

  ValidationError({required this.loc, required this.msg, required this.type});

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          runtimeType == other.runtimeType &&
          loc == other.loc &&
          msg == other.msg &&
          type == other.type;

  @override
  int get hashCode => loc.hashCode ^ msg.hashCode ^ type.hashCode;

  @override
  String toString() => 'ValidationError(loc: $loc, msg: $msg, type: $type)';
}

/// HTTP验证错误响应
@JsonSerializable()
class HTTPValidationError {
  final List<ValidationError> detail;

  HTTPValidationError({required this.detail});

  factory HTTPValidationError.fromJson(Map<String, dynamic> json) =>
      _$HTTPValidationErrorFromJson(json);
  Map<String, dynamic> toJson() => _$HTTPValidationErrorToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HTTPValidationError &&
          runtimeType == other.runtimeType &&
          detail == other.detail;

  @override
  int get hashCode => detail.hashCode;

  @override
  String toString() => 'HTTPValidationError(detail: $detail)';
}

/// 分页响应基类
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedResponse &&
          runtimeType == other.runtimeType &&
          items == other.items &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize &&
          totalPages == other.totalPages;

  @override
  int get hashCode =>
      items.hashCode ^
      total.hashCode ^
      page.hashCode ^
      pageSize.hashCode ^
      totalPages.hashCode;

  @override
  String toString() =>
      'PaginatedResponse(items: $items, total: $total, page: $page, pageSize: $pageSize, totalPages: $totalPages)';
}

/// 成功响应
@JsonSerializable(genericArgumentFactories: true)
class SuccessResponse<T> {
  final bool success;
  final String message;
  final T? data;

  SuccessResponse({required this.success, required this.message, this.data});

  factory SuccessResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$SuccessResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$SuccessResponseToJson(this, toJsonT);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuccessResponse &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          message == other.message &&
          data == other.data;

  @override
  int get hashCode => success.hashCode ^ message.hashCode ^ data.hashCode;

  @override
  String toString() =>
      'SuccessResponse(success: $success, message: $message, data: $data)';
}
