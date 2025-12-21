// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_notification_notification_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppSchemasNotificationNotificationType _$push =
    const AppSchemasNotificationNotificationType._('push');
const AppSchemasNotificationNotificationType _$email =
    const AppSchemasNotificationNotificationType._('email');
const AppSchemasNotificationNotificationType _$sms =
    const AppSchemasNotificationNotificationType._('sms');
const AppSchemasNotificationNotificationType _$webhook =
    const AppSchemasNotificationNotificationType._('webhook');

AppSchemasNotificationNotificationType _$valueOf(String name) {
  switch (name) {
    case 'push':
      return _$push;
    case 'email':
      return _$email;
    case 'sms':
      return _$sms;
    case 'webhook':
      return _$webhook;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppSchemasNotificationNotificationType> _$values = BuiltSet<
    AppSchemasNotificationNotificationType>(const <AppSchemasNotificationNotificationType>[
  _$push,
  _$email,
  _$sms,
  _$webhook,
]);

class _$AppSchemasNotificationNotificationTypeMeta {
  const _$AppSchemasNotificationNotificationTypeMeta();
  AppSchemasNotificationNotificationType get push => _$push;
  AppSchemasNotificationNotificationType get email => _$email;
  AppSchemasNotificationNotificationType get sms => _$sms;
  AppSchemasNotificationNotificationType get webhook => _$webhook;
  AppSchemasNotificationNotificationType valueOf(String name) =>
      _$valueOf(name);
  BuiltSet<AppSchemasNotificationNotificationType> get values => _$values;
}

abstract class _$AppSchemasNotificationNotificationTypeMixin {
  // ignore: non_constant_identifier_names
  _$AppSchemasNotificationNotificationTypeMeta
      get AppSchemasNotificationNotificationType =>
          const _$AppSchemasNotificationNotificationTypeMeta();
}

Serializer<AppSchemasNotificationNotificationType>
    _$appSchemasNotificationNotificationTypeSerializer =
    _$AppSchemasNotificationNotificationTypeSerializer();

class _$AppSchemasNotificationNotificationTypeSerializer
    implements PrimitiveSerializer<AppSchemasNotificationNotificationType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'push': 'push',
    'email': 'email',
    'sms': 'sms',
    'webhook': 'webhook',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'push': 'push',
    'email': 'email',
    'sms': 'sms',
    'webhook': 'webhook',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AppSchemasNotificationNotificationType
  ];
  @override
  final String wireName = 'AppSchemasNotificationNotificationType';

  @override
  Object serialize(Serializers serializers,
          AppSchemasNotificationNotificationType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AppSchemasNotificationNotificationType deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AppSchemasNotificationNotificationType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
