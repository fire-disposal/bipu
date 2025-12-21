//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_schemas_notification_notification_type.g.dart';

class AppSchemasNotificationNotificationType extends EnumClass {
  /// 通知类型
  @BuiltValueEnumConst(wireName: r'push')
  static const AppSchemasNotificationNotificationType push = _$push;

  /// 通知类型
  @BuiltValueEnumConst(wireName: r'email')
  static const AppSchemasNotificationNotificationType email = _$email;

  /// 通知类型
  @BuiltValueEnumConst(wireName: r'sms')
  static const AppSchemasNotificationNotificationType sms = _$sms;

  /// 通知类型
  @BuiltValueEnumConst(wireName: r'webhook')
  static const AppSchemasNotificationNotificationType webhook = _$webhook;

  static Serializer<AppSchemasNotificationNotificationType> get serializer =>
      _$appSchemasNotificationNotificationTypeSerializer;

  const AppSchemasNotificationNotificationType._(String name) : super(name);

  static BuiltSet<AppSchemasNotificationNotificationType> get values =>
      _$values;
  static AppSchemasNotificationNotificationType valueOf(String name) =>
      _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AppSchemasNotificationNotificationTypeMixin = Object
    with _$AppSchemasNotificationNotificationTypeMixin;
