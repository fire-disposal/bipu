// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationStats extends NotificationStats {
  @override
  final int total;
  @override
  final int unread;
  @override
  final int read;
  @override
  final int deleted;

  factory _$NotificationStats(
          [void Function(NotificationStatsBuilder)? updates]) =>
      (NotificationStatsBuilder()..update(updates))._build();

  _$NotificationStats._(
      {required this.total,
      required this.unread,
      required this.read,
      required this.deleted})
      : super._();
  @override
  NotificationStats rebuild(void Function(NotificationStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationStatsBuilder toBuilder() =>
      NotificationStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationStats &&
        total == other.total &&
        unread == other.unread &&
        read == other.read &&
        deleted == other.deleted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, unread.hashCode);
    _$hash = $jc(_$hash, read.hashCode);
    _$hash = $jc(_$hash, deleted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationStats')
          ..add('total', total)
          ..add('unread', unread)
          ..add('read', read)
          ..add('deleted', deleted))
        .toString();
  }
}

class NotificationStatsBuilder
    implements Builder<NotificationStats, NotificationStatsBuilder> {
  _$NotificationStats? _$v;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _unread;
  int? get unread => _$this._unread;
  set unread(int? unread) => _$this._unread = unread;

  int? _read;
  int? get read => _$this._read;
  set read(int? read) => _$this._read = read;

  int? _deleted;
  int? get deleted => _$this._deleted;
  set deleted(int? deleted) => _$this._deleted = deleted;

  NotificationStatsBuilder() {
    NotificationStats._defaults(this);
  }

  NotificationStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _unread = $v.unread;
      _read = $v.read;
      _deleted = $v.deleted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationStats other) {
    _$v = other as _$NotificationStats;
  }

  @override
  void update(void Function(NotificationStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationStats build() => _build();

  _$NotificationStats _build() {
    final _$result = _$v ??
        _$NotificationStats._(
          total: BuiltValueNullFieldError.checkNotNull(
              total, r'NotificationStats', 'total'),
          unread: BuiltValueNullFieldError.checkNotNull(
              unread, r'NotificationStats', 'unread'),
          read: BuiltValueNullFieldError.checkNotNull(
              read, r'NotificationStats', 'read'),
          deleted: BuiltValueNullFieldError.checkNotNull(
              deleted, r'NotificationStats', 'deleted'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
