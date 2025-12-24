// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceCreate extends DeviceCreate {
  @override
  final String deviceIdentifier;
  @override
  final int userId;
  @override
  final DateTime? lastSeen;

  factory _$DeviceCreate([void Function(DeviceCreateBuilder)? updates]) =>
      (DeviceCreateBuilder()..update(updates))._build();

  _$DeviceCreate._(
      {required this.deviceIdentifier, required this.userId, this.lastSeen})
      : super._();
  @override
  DeviceCreate rebuild(void Function(DeviceCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceCreateBuilder toBuilder() => DeviceCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceCreate &&
        deviceIdentifier == other.deviceIdentifier &&
        userId == other.userId &&
        lastSeen == other.lastSeen;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deviceIdentifier.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, lastSeen.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceCreate')
          ..add('deviceIdentifier', deviceIdentifier)
          ..add('userId', userId)
          ..add('lastSeen', lastSeen))
        .toString();
  }
}

class DeviceCreateBuilder
    implements Builder<DeviceCreate, DeviceCreateBuilder> {
  _$DeviceCreate? _$v;

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

  DeviceCreateBuilder() {
    DeviceCreate._defaults(this);
  }

  DeviceCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deviceIdentifier = $v.deviceIdentifier;
      _userId = $v.userId;
      _lastSeen = $v.lastSeen;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceCreate other) {
    _$v = other as _$DeviceCreate;
  }

  @override
  void update(void Function(DeviceCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceCreate build() => _build();

  _$DeviceCreate _build() {
    final _$result = _$v ??
        _$DeviceCreate._(
          deviceIdentifier: BuiltValueNullFieldError.checkNotNull(
              deviceIdentifier, r'DeviceCreate', 'deviceIdentifier'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'DeviceCreate', 'userId'),
          lastSeen: lastSeen,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
