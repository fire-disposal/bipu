// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceResponse extends DeviceResponse {
  @override
  final String name;
  @override
  final String deviceType;
  @override
  final String deviceId;
  @override
  final String? description;
  @override
  final String? status;
  @override
  final BuiltMap<String, JsonObject?>? config;
  @override
  final String? location;
  @override
  final bool? isActive;
  @override
  final int id;
  @override
  final int userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? lastSeenAt;

  factory _$DeviceResponse([void Function(DeviceResponseBuilder)? updates]) =>
      (DeviceResponseBuilder()..update(updates))._build();

  _$DeviceResponse._(
      {required this.name,
      required this.deviceType,
      required this.deviceId,
      this.description,
      this.status,
      this.config,
      this.location,
      this.isActive,
      required this.id,
      required this.userId,
      required this.createdAt,
      this.updatedAt,
      this.lastSeenAt})
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
        name == other.name &&
        deviceType == other.deviceType &&
        deviceId == other.deviceId &&
        description == other.description &&
        status == other.status &&
        config == other.config &&
        location == other.location &&
        isActive == other.isActive &&
        id == other.id &&
        userId == other.userId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        lastSeenAt == other.lastSeenAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, deviceType.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, config.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, lastSeenAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceResponse')
          ..add('name', name)
          ..add('deviceType', deviceType)
          ..add('deviceId', deviceId)
          ..add('description', description)
          ..add('status', status)
          ..add('config', config)
          ..add('location', location)
          ..add('isActive', isActive)
          ..add('id', id)
          ..add('userId', userId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('lastSeenAt', lastSeenAt))
        .toString();
  }
}

class DeviceResponseBuilder
    implements Builder<DeviceResponse, DeviceResponseBuilder> {
  _$DeviceResponse? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _deviceType;
  String? get deviceType => _$this._deviceType;
  set deviceType(String? deviceType) => _$this._deviceType = deviceType;

  String? _deviceId;
  String? get deviceId => _$this._deviceId;
  set deviceId(String? deviceId) => _$this._deviceId = deviceId;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  MapBuilder<String, JsonObject?>? _config;
  MapBuilder<String, JsonObject?> get config =>
      _$this._config ??= MapBuilder<String, JsonObject?>();
  set config(MapBuilder<String, JsonObject?>? config) =>
      _$this._config = config;

  String? _location;
  String? get location => _$this._location;
  set location(String? location) => _$this._location = location;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DateTime? _lastSeenAt;
  DateTime? get lastSeenAt => _$this._lastSeenAt;
  set lastSeenAt(DateTime? lastSeenAt) => _$this._lastSeenAt = lastSeenAt;

  DeviceResponseBuilder() {
    DeviceResponse._defaults(this);
  }

  DeviceResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _deviceType = $v.deviceType;
      _deviceId = $v.deviceId;
      _description = $v.description;
      _status = $v.status;
      _config = $v.config?.toBuilder();
      _location = $v.location;
      _isActive = $v.isActive;
      _id = $v.id;
      _userId = $v.userId;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _lastSeenAt = $v.lastSeenAt;
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
    _$DeviceResponse _$result;
    try {
      _$result = _$v ??
          _$DeviceResponse._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'DeviceResponse', 'name'),
            deviceType: BuiltValueNullFieldError.checkNotNull(
                deviceType, r'DeviceResponse', 'deviceType'),
            deviceId: BuiltValueNullFieldError.checkNotNull(
                deviceId, r'DeviceResponse', 'deviceId'),
            description: description,
            status: status,
            config: _config?.build(),
            location: location,
            isActive: isActive,
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'DeviceResponse', 'id'),
            userId: BuiltValueNullFieldError.checkNotNull(
                userId, r'DeviceResponse', 'userId'),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'DeviceResponse', 'createdAt'),
            updatedAt: updatedAt,
            lastSeenAt: lastSeenAt,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'config';
        _config?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DeviceResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
