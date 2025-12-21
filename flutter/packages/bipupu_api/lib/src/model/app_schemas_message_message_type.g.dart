// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_message_message_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppSchemasMessageMessageType _$system =
    const AppSchemasMessageMessageType._('system');
const AppSchemasMessageMessageType _$device =
    const AppSchemasMessageMessageType._('device');
const AppSchemasMessageMessageType _$user =
    const AppSchemasMessageMessageType._('user');
const AppSchemasMessageMessageType _$alert =
    const AppSchemasMessageMessageType._('alert');
const AppSchemasMessageMessageType _$notification =
    const AppSchemasMessageMessageType._('notification');

AppSchemasMessageMessageType _$valueOf(String name) {
  switch (name) {
    case 'system':
      return _$system;
    case 'device':
      return _$device;
    case 'user':
      return _$user;
    case 'alert':
      return _$alert;
    case 'notification':
      return _$notification;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppSchemasMessageMessageType> _$values =
    BuiltSet<AppSchemasMessageMessageType>(const <AppSchemasMessageMessageType>[
  _$system,
  _$device,
  _$user,
  _$alert,
  _$notification,
]);

class _$AppSchemasMessageMessageTypeMeta {
  const _$AppSchemasMessageMessageTypeMeta();
  AppSchemasMessageMessageType get system => _$system;
  AppSchemasMessageMessageType get device => _$device;
  AppSchemasMessageMessageType get user => _$user;
  AppSchemasMessageMessageType get alert => _$alert;
  AppSchemasMessageMessageType get notification => _$notification;
  AppSchemasMessageMessageType valueOf(String name) => _$valueOf(name);
  BuiltSet<AppSchemasMessageMessageType> get values => _$values;
}

abstract class _$AppSchemasMessageMessageTypeMixin {
  // ignore: non_constant_identifier_names
  _$AppSchemasMessageMessageTypeMeta get AppSchemasMessageMessageType =>
      const _$AppSchemasMessageMessageTypeMeta();
}

Serializer<AppSchemasMessageMessageType>
    _$appSchemasMessageMessageTypeSerializer =
    _$AppSchemasMessageMessageTypeSerializer();

class _$AppSchemasMessageMessageTypeSerializer
    implements PrimitiveSerializer<AppSchemasMessageMessageType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'system': 'system',
    'device': 'device',
    'user': 'user',
    'alert': 'alert',
    'notification': 'notification',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'system': 'system',
    'device': 'device',
    'user': 'user',
    'alert': 'alert',
    'notification': 'notification',
  };

  @override
  final Iterable<Type> types = const <Type>[AppSchemasMessageMessageType];
  @override
  final String wireName = 'AppSchemasMessageMessageType';

  @override
  Object serialize(Serializers serializers, AppSchemasMessageMessageType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AppSchemasMessageMessageType deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AppSchemasMessageMessageType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
