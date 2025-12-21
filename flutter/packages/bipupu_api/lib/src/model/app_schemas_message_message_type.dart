//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_schemas_message_message_type.g.dart';

class AppSchemasMessageMessageType extends EnumClass {
  /// 消息类型
  @BuiltValueEnumConst(wireName: r'system')
  static const AppSchemasMessageMessageType system = _$system;

  /// 消息类型
  @BuiltValueEnumConst(wireName: r'device')
  static const AppSchemasMessageMessageType device = _$device;

  /// 消息类型
  @BuiltValueEnumConst(wireName: r'user')
  static const AppSchemasMessageMessageType user = _$user;

  /// 消息类型
  @BuiltValueEnumConst(wireName: r'alert')
  static const AppSchemasMessageMessageType alert = _$alert;

  /// 消息类型
  @BuiltValueEnumConst(wireName: r'notification')
  static const AppSchemasMessageMessageType notification = _$notification;

  static Serializer<AppSchemasMessageMessageType> get serializer =>
      _$appSchemasMessageMessageTypeSerializer;

  const AppSchemasMessageMessageType._(String name) : super(name);

  static BuiltSet<AppSchemasMessageMessageType> get values => _$values;
  static AppSchemasMessageMessageType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AppSchemasMessageMessageTypeMixin = Object
    with _$AppSchemasMessageMessageTypeMixin;
