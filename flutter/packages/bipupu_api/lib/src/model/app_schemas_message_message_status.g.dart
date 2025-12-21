// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_message_message_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppSchemasMessageMessageStatus _$unread =
    const AppSchemasMessageMessageStatus._('unread');
const AppSchemasMessageMessageStatus _$read =
    const AppSchemasMessageMessageStatus._('read');
const AppSchemasMessageMessageStatus _$archived =
    const AppSchemasMessageMessageStatus._('archived');

AppSchemasMessageMessageStatus _$valueOf(String name) {
  switch (name) {
    case 'unread':
      return _$unread;
    case 'read':
      return _$read;
    case 'archived':
      return _$archived;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppSchemasMessageMessageStatus> _$values = BuiltSet<
    AppSchemasMessageMessageStatus>(const <AppSchemasMessageMessageStatus>[
  _$unread,
  _$read,
  _$archived,
]);

class _$AppSchemasMessageMessageStatusMeta {
  const _$AppSchemasMessageMessageStatusMeta();
  AppSchemasMessageMessageStatus get unread => _$unread;
  AppSchemasMessageMessageStatus get read => _$read;
  AppSchemasMessageMessageStatus get archived => _$archived;
  AppSchemasMessageMessageStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<AppSchemasMessageMessageStatus> get values => _$values;
}

abstract class _$AppSchemasMessageMessageStatusMixin {
  // ignore: non_constant_identifier_names
  _$AppSchemasMessageMessageStatusMeta get AppSchemasMessageMessageStatus =>
      const _$AppSchemasMessageMessageStatusMeta();
}

Serializer<AppSchemasMessageMessageStatus>
    _$appSchemasMessageMessageStatusSerializer =
    _$AppSchemasMessageMessageStatusSerializer();

class _$AppSchemasMessageMessageStatusSerializer
    implements PrimitiveSerializer<AppSchemasMessageMessageStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'unread': 'unread',
    'read': 'read',
    'archived': 'archived',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'unread': 'unread',
    'read': 'read',
    'archived': 'archived',
  };

  @override
  final Iterable<Type> types = const <Type>[AppSchemasMessageMessageStatus];
  @override
  final String wireName = 'AppSchemasMessageMessageStatus';

  @override
  Object serialize(
          Serializers serializers, AppSchemasMessageMessageStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AppSchemasMessageMessageStatus deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AppSchemasMessageMessageStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
