// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models_message_message_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppModelsMessageMessageType _$system =
    const AppModelsMessageMessageType._('system');
const AppModelsMessageMessageType _$device =
    const AppModelsMessageMessageType._('device');
const AppModelsMessageMessageType _$user =
    const AppModelsMessageMessageType._('user');
const AppModelsMessageMessageType _$alert =
    const AppModelsMessageMessageType._('alert');
const AppModelsMessageMessageType _$notification =
    const AppModelsMessageMessageType._('notification');

AppModelsMessageMessageType _$valueOf(String name) {
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

final BuiltSet<AppModelsMessageMessageType> _$values =
    BuiltSet<AppModelsMessageMessageType>(const <AppModelsMessageMessageType>[
  _$system,
  _$device,
  _$user,
  _$alert,
  _$notification,
]);

class _$AppModelsMessageMessageTypeMeta {
  const _$AppModelsMessageMessageTypeMeta();
  AppModelsMessageMessageType get system => _$system;
  AppModelsMessageMessageType get device => _$device;
  AppModelsMessageMessageType get user => _$user;
  AppModelsMessageMessageType get alert => _$alert;
  AppModelsMessageMessageType get notification => _$notification;
  AppModelsMessageMessageType valueOf(String name) => _$valueOf(name);
  BuiltSet<AppModelsMessageMessageType> get values => _$values;
}

abstract class _$AppModelsMessageMessageTypeMixin {
  // ignore: non_constant_identifier_names
  _$AppModelsMessageMessageTypeMeta get AppModelsMessageMessageType =>
      const _$AppModelsMessageMessageTypeMeta();
}

Serializer<AppModelsMessageMessageType>
    _$appModelsMessageMessageTypeSerializer =
    _$AppModelsMessageMessageTypeSerializer();

class _$AppModelsMessageMessageTypeSerializer
    implements PrimitiveSerializer<AppModelsMessageMessageType> {
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
  final Iterable<Type> types = const <Type>[AppModelsMessageMessageType];
  @override
  final String wireName = 'AppModelsMessageMessageType';

  @override
  Object serialize(Serializers serializers, AppModelsMessageMessageType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AppModelsMessageMessageType deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AppModelsMessageMessageType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
