// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_notification_notification_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppSchemasNotificationNotificationStatus _$unread =
    const AppSchemasNotificationNotificationStatus._('unread');
const AppSchemasNotificationNotificationStatus _$read =
    const AppSchemasNotificationNotificationStatus._('read');
const AppSchemasNotificationNotificationStatus _$deleted =
    const AppSchemasNotificationNotificationStatus._('deleted');

AppSchemasNotificationNotificationStatus _$valueOf(String name) {
  switch (name) {
    case 'unread':
      return _$unread;
    case 'read':
      return _$read;
    case 'deleted':
      return _$deleted;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppSchemasNotificationNotificationStatus> _$values = BuiltSet<
    AppSchemasNotificationNotificationStatus>(const <AppSchemasNotificationNotificationStatus>[
  _$unread,
  _$read,
  _$deleted,
]);

class _$AppSchemasNotificationNotificationStatusMeta {
  const _$AppSchemasNotificationNotificationStatusMeta();
  AppSchemasNotificationNotificationStatus get unread => _$unread;
  AppSchemasNotificationNotificationStatus get read => _$read;
  AppSchemasNotificationNotificationStatus get deleted => _$deleted;
  AppSchemasNotificationNotificationStatus valueOf(String name) =>
      _$valueOf(name);
  BuiltSet<AppSchemasNotificationNotificationStatus> get values => _$values;
}

abstract class _$AppSchemasNotificationNotificationStatusMixin {
  // ignore: non_constant_identifier_names
  _$AppSchemasNotificationNotificationStatusMeta
      get AppSchemasNotificationNotificationStatus =>
          const _$AppSchemasNotificationNotificationStatusMeta();
}

Serializer<AppSchemasNotificationNotificationStatus>
    _$appSchemasNotificationNotificationStatusSerializer =
    _$AppSchemasNotificationNotificationStatusSerializer();

class _$AppSchemasNotificationNotificationStatusSerializer
    implements PrimitiveSerializer<AppSchemasNotificationNotificationStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'unread': 'unread',
    'read': 'read',
    'deleted': 'deleted',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'unread': 'unread',
    'read': 'read',
    'deleted': 'deleted',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AppSchemasNotificationNotificationStatus
  ];
  @override
  final String wireName = 'AppSchemasNotificationNotificationStatus';

  @override
  Object serialize(Serializers serializers,
          AppSchemasNotificationNotificationStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AppSchemasNotificationNotificationStatus deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AppSchemasNotificationNotificationStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
