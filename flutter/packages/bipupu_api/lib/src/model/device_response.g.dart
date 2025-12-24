// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceResponse extends DeviceResponse {
  @override
  final String deviceIdentifier;
  @override
  final int userId;
  @override
  final DateTime? lastSeen;
  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  factory _$DeviceResponse([void Function(DeviceResponseBuilder)? updates]) =>
      (DeviceResponseBuilder()..update(updates))._build();

  _$DeviceResponse._(
      {required this.deviceIdentifier,
      required this.userId,
      this.lastSeen,
      required this.id,
      required this.createdAt,
      this.updatedAt})
      : super._();
  @override
  DeviceResponse rebuild(void Function(DeviceResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceResponseBuilder toBuilder() => DeviceResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceResponse &&
        deviceIdentifier == other.deviceIdentifier &&
        userId == other.userId &&
        lastSeen == other.lastSeen &&
        id == other.id &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deviceIdentifier.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, lastSeen.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceResponse')
          ..add('deviceIdentifier', deviceIdentifier)
          ..add('userId', userId)
          ..add('lastSeen', lastSeen)
          ..add('id', id)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class DeviceResponseBuilder
    implements Builder<DeviceResponse, DeviceResponseBuilder> {
  _$DeviceResponse? _$v;

  String? _deviceIdentifier;
  String? get deviceIdentifier => _$this._deviceIdentifier;
  set deviceIdentifier(String? deviceIdentifier) =>
      _$this._deviceIdentifier = deviceIdentifier;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  DateTime? _lastSeen;
  DateTime? get lastSeen => _$this._lastSeen;
  set lastSeen(DateTime? lastSeen) => _$this._lastSeen = lastSeen;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DeviceResponseBuilder() {
    DeviceResponse._defaults(this);
  }

  DeviceResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deviceIdentifier = $v.deviceIdentifier;
      _userId = $v.userId;
      _lastSeen = $v.lastSeen;
      _id = $v.id;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceResponse other) {
    _$v = other as _$DeviceResponse;
  }

  @override
  void update(void Function(DeviceResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceResponse build() => _build();

  _$DeviceResponse _build() {
    final _$result = _$v ??
        _$DeviceResponse._(
          deviceIdentifier: BuiltValueNullFieldError.checkNotNull(
              deviceIdentifier, r'DeviceResponse', 'deviceIdentifier'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'DeviceResponse', 'userId'),
          lastSeen: lastSeen,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'DeviceResponse', 'id'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'DeviceResponse', 'createdAt'),
          updatedAt: updatedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
