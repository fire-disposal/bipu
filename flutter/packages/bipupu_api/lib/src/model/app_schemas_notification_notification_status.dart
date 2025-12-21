//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_schemas_notification_notification_status.g.dart';

class AppSchemasNotificationNotificationStatus extends EnumClass {
  /// 通知状态
  @BuiltValueEnumConst(wireName: r'pending')
  static const AppSchemasNotificationNotificationStatus pending = _$pending;

  /// 通知状态
  @BuiltValueEnumConst(wireName: r'sent')
  static const AppSchemasNotificationNotificationStatus sent = _$sent;

  /// 通知状态
  @BuiltValueEnumConst(wireName: r'failed')
  static const AppSchemasNotificationNotificationStatus failed = _$failed;

  /// 通知状态
  @BuiltValueEnumConst(wireName: r'cancelled')
  static const AppSchemasNotificationNotificationStatus cancelled = _$cancelled;

  static Serializer<AppSchemasNotificationNotificationStatus> get serializer =>
      _$appSchemasNotificationNotificationStatusSerializer;

  const AppSchemasNotificationNotificationStatus._(String name) : super(name);

  static BuiltSet<AppSchemasNotificationNotificationStatus> get values =>
      _$values;
  static AppSchemasNotificationNotificationStatus valueOf(String name) =>
      _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AppSchemasNotificationNotificationStatusMixin = Object
    with _$AppSchemasNotificationNotificationStatusMixin;
