// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceUpdate extends DeviceUpdate {
  @override
  final String? name;
  @override
  final String? deviceType;
  @override
  final String? deviceId;
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
  final DateTime? lastSeenAt;

  factory _$DeviceUpdate([void Function(DeviceUpdateBuilder)? updates]) =>
      (DeviceUpdateBuilder()..update(updates))._build();

  _$DeviceUpdate._(
      {this.name,
      this.deviceType,
      this.deviceId,
      this.description,
      this.status,
      this.config,
      this.location,
      this.isActive,
      this.lastSeenAt})
      : super._();
  @override
  DeviceUpdate rebuild(void Function(DeviceUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceUpdateBuilder toBuilder() => DeviceUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceUpdate &&
        name == other.name &&
        deviceType == other.deviceType &&
        deviceId == other.deviceId &&
        description == other.description &&
        status == other.status &&
        config == other.config &&
        location == other.location &&
        isActive == other.isActive &&
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
    _$hash = $jc(_$hash, lastSeenAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceUpdate')
          ..add('name', name)
          ..add('deviceType', deviceType)
          ..add('deviceId', deviceId)
          ..add('description', description)
          ..add('status', status)
          ..add('config', config)
          ..add('location', location)
          ..add('isActive', isActive)
          ..add('lastSeenAt', lastSeenAt))
        .toString();
  }
}

class DeviceUpdateBuilder
    implements Builder<DeviceUpdate, DeviceUpdateBuilder> {
  _$DeviceUpdate? _$v;

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

  DateTime? _lastSeenAt;
  DateTime? get lastSeenAt => _$this._lastSeenAt;
  set lastSeenAt(DateTime? lastSeenAt) => _$this._lastSeenAt = lastSeenAt;

  DeviceUpdateBuilder() {
    DeviceUpdate._defaults(this);
  }

  DeviceUpdateBuilder get _$this {
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
      _lastSeenAt = $v.lastSeenAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceUpdate other) {
    _$v = other as _$DeviceUpdate;
  }

  @override
  void update(void Function(DeviceUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceUpdate build() => _build();

  _$DeviceUpdate _build() {
    _$DeviceUpdate _$result;
    try {
      _$result = _$v ??
          _$DeviceUpdate._(
            name: name,
            deviceType: deviceType,
            deviceId: deviceId,
            description: description,
            status: status,
            config: _config?.build(),
            location: location,
            isActive: isActive,
            lastSeenAt: lastSeenAt,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'config';
        _config?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DeviceUpdate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
