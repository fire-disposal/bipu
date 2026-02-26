// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// 推送时间来源枚举
@JsonEnum()
enum PushTimeSource {
  @JsonValue('subscription')
  subscription('subscription'),
  @JsonValue('service_default')
  serviceDefault('service_default'),
  @JsonValue('none')
  none('none'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const PushTimeSource(this.json);

  factory PushTimeSource.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<PushTimeSource> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
