// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceStats extends DeviceStats {
  @override
  final int total;
  @override
  final int online;
  @override
  final int offline;
  @override
  final int error;
  @override
  final int maintenance;

  factory _$DeviceStats([void Function(DeviceStatsBuilder)? updates]) =>
      (DeviceStatsBuilder()..update(updates))._build();

  _$DeviceStats._(
      {required this.total,
      required this.online,
      required this.offline,
      required this.error,
      required this.maintenance})
      : super._();
  @override
  DeviceStats rebuild(void Function(DeviceStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceStatsBuilder toBuilder() => DeviceStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceStats &&
        total == other.total &&
        online == other.online &&
        offline == other.offline &&
        error == other.error &&
        maintenance == other.maintenance;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, online.hashCode);
    _$hash = $jc(_$hash, offline.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, maintenance.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceStats')
          ..add('total', total)
          ..add('online', online)
          ..add('offline', offline)
          ..add('error', error)
          ..add('maintenance', maintenance))
        .toString();
  }
}

class DeviceStatsBuilder implements Builder<DeviceStats, DeviceStatsBuilder> {
  _$DeviceStats? _$v;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _online;
  int? get online => _$this._online;
  set online(int? online) => _$this._online = online;

  int? _offline;
  int? get offline => _$this._offline;
  set offline(int? offline) => _$this._offline = offline;

  int? _error;
  int? get error => _$this._error;
  set error(int? error) => _$this._error = error;

  int? _maintenance;
  int? get maintenance => _$this._maintenance;
  set maintenance(int? maintenance) => _$this._maintenance = maintenance;

  DeviceStatsBuilder() {
    DeviceStats._defaults(this);
  }

  DeviceStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _online = $v.online;
      _offline = $v.offline;
      _error = $v.error;
      _maintenance = $v.maintenance;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceStats other) {
    _$v = other as _$DeviceStats;
  }

  @override
  void update(void Function(DeviceStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceStats build() => _build();

  _$DeviceStats _build() {
    final _$result = _$v ??
        _$DeviceStats._(
          total: BuiltValueNullFieldError.checkNotNull(
              total, r'DeviceStats', 'total'),
          online: BuiltValueNullFieldError.checkNotNull(
              online, r'DeviceStats', 'online'),
          offline: BuiltValueNullFieldError.checkNotNull(
              offline, r'DeviceStats', 'offline'),
          error: BuiltValueNullFieldError.checkNotNull(
              error, r'DeviceStats', 'error'),
          maintenance: BuiltValueNullFieldError.checkNotNull(
              maintenance, r'DeviceStats', 'maintenance'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
