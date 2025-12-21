// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_notification_notification_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppSchemasNotificationNotificationStatus _$pending =
    const AppSchemasNotificationNotificationStatus._('pending');
const AppSchemasNotificationNotificationStatus _$sent =
    const AppSchemasNotificationNotificationStatus._('sent');
const AppSchemasNotificationNotificationStatus _$failed =
    const AppSchemasNotificationNotificationStatus._('failed');
const AppSchemasNotificationNotificationStatus _$cancelled =
    const AppSchemasNotificationNotificationStatus._('cancelled');

AppSchemasNotificationNotificationStatus _$valueOf(String name) {
  switch (name) {
    case 'pending':
      return _$pending;
    case 'sent':
      return _$sent;
    case 'failed':
      return _$failed;
    case 'cancelled':
      return _$cancelled;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppSchemasNotificationNotificationStatus> _$values = BuiltSet<
    AppSchemasNotificationNotificationStatus>(const <AppSchemasNotificationNotificationStatus>[
  _$pending,
  _$sent,
  _$failed,
  _$cancelled,
]);

class _$AppSchemasNotificationNotificationStatusMeta {
  const _$AppSchemasNotificationNotificationStatusMeta();
  AppSchemasNotificationNotificationStatus get pending => _$pending;
  AppSchemasNotificationNotificationStatus get sent => _$sent;
  AppSchemasNotificationNotificationStatus get failed => _$failed;
  AppSchemasNotificationNotificationStatus get cancelled => _$cancelled;
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
    'pending': 'pending',
    'sent': 'sent',
    'failed': 'failed',
    'cancelled': 'cancelled',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'sent': 'sent',
    'failed': 'failed',
    'cancelled': 'cancelled',
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
