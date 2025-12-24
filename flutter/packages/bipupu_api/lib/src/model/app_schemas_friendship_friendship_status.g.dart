// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_friendship_friendship_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppSchemasFriendshipFriendshipStatus _$pending =
    const AppSchemasFriendshipFriendshipStatus._('pending');
const AppSchemasFriendshipFriendshipStatus _$accepted =
    const AppSchemasFriendshipFriendshipStatus._('accepted');
const AppSchemasFriendshipFriendshipStatus _$blocked =
    const AppSchemasFriendshipFriendshipStatus._('blocked');

AppSchemasFriendshipFriendshipStatus _$valueOf(String name) {
  switch (name) {
    case 'pending':
      return _$pending;
    case 'accepted':
      return _$accepted;
    case 'blocked':
      return _$blocked;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppSchemasFriendshipFriendshipStatus> _$values = BuiltSet<
    AppSchemasFriendshipFriendshipStatus>(const <AppSchemasFriendshipFriendshipStatus>[
  _$pending,
  _$accepted,
  _$blocked,
]);

class _$AppSchemasFriendshipFriendshipStatusMeta {
  const _$AppSchemasFriendshipFriendshipStatusMeta();
  AppSchemasFriendshipFriendshipStatus get pending => _$pending;
  AppSchemasFriendshipFriendshipStatus get accepted => _$accepted;
  AppSchemasFriendshipFriendshipStatus get blocked => _$blocked;
  AppSchemasFriendshipFriendshipStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<AppSchemasFriendshipFriendshipStatus> get values => _$values;
}

abstract class _$AppSchemasFriendshipFriendshipStatusMixin {
  // ignore: non_constant_identifier_names
  _$AppSchemasFriendshipFriendshipStatusMeta
      get AppSchemasFriendshipFriendshipStatus =>
          const _$AppSchemasFriendshipFriendshipStatusMeta();
}

Serializer<AppSchemasFriendshipFriendshipStatus>
    _$appSchemasFriendshipFriendshipStatusSerializer =
    _$AppSchemasFriendshipFriendshipStatusSerializer();

class _$AppSchemasFriendshipFriendshipStatusSerializer
    implements PrimitiveSerializer<AppSchemasFriendshipFriendshipStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'accepted': 'accepted',
    'blocked': 'blocked',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'accepted': 'accepted',
    'blocked': 'blocked',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AppSchemasFriendshipFriendshipStatus
  ];
  @override
  final String wireName = 'AppSchemasFriendshipFriendshipStatus';

  @override
  Object serialize(
          Serializers serializers, AppSchemasFriendshipFriendshipStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AppSchemasFriendshipFriendshipStatus deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AppSchemasFriendshipFriendshipStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
