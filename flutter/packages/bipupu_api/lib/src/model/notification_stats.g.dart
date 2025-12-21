// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationStats extends NotificationStats {
  @override
  final int total;
  @override
  final int pending;
  @override
  final int sent;
  @override
  final int failed;
  @override
  final int cancelled;
  @override
  final BuiltMap<String, JsonObject?> byType;

  factory _$NotificationStats(
          [void Function(NotificationStatsBuilder)? updates]) =>
      (NotificationStatsBuilder()..update(updates))._build();

  _$NotificationStats._(
      {required this.total,
      required this.pending,
      required this.sent,
      required this.failed,
      required this.cancelled,
      required this.byType})
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
        pending == other.pending &&
        sent == other.sent &&
        failed == other.failed &&
        cancelled == other.cancelled &&
        byType == other.byType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, pending.hashCode);
    _$hash = $jc(_$hash, sent.hashCode);
    _$hash = $jc(_$hash, failed.hashCode);
    _$hash = $jc(_$hash, cancelled.hashCode);
    _$hash = $jc(_$hash, byType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationStats')
          ..add('total', total)
          ..add('pending', pending)
          ..add('sent', sent)
          ..add('failed', failed)
          ..add('cancelled', cancelled)
          ..add('byType', byType))
        .toString();
  }
}

class NotificationStatsBuilder
    implements Builder<NotificationStats, NotificationStatsBuilder> {
  _$NotificationStats? _$v;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _pending;
  int? get pending => _$this._pending;
  set pending(int? pending) => _$this._pending = pending;

  int? _sent;
  int? get sent => _$this._sent;
  set sent(int? sent) => _$this._sent = sent;

  int? _failed;
  int? get failed => _$this._failed;
  set failed(int? failed) => _$this._failed = failed;

  int? _cancelled;
  int? get cancelled => _$this._cancelled;
  set cancelled(int? cancelled) => _$this._cancelled = cancelled;

  MapBuilder<String, JsonObject?>? _byType;
  MapBuilder<String, JsonObject?> get byType =>
      _$this._byType ??= MapBuilder<String, JsonObject?>();
  set byType(MapBuilder<String, JsonObject?>? byType) =>
      _$this._byType = byType;

  NotificationStatsBuilder() {
    NotificationStats._defaults(this);
  }

  NotificationStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _pending = $v.pending;
      _sent = $v.sent;
      _failed = $v.failed;
      _cancelled = $v.cancelled;
      _byType = $v.byType.toBuilder();
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
    _$NotificationStats _$result;
    try {
      _$result = _$v ??
          _$NotificationStats._(
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'NotificationStats', 'total'),
            pending: BuiltValueNullFieldError.checkNotNull(
                pending, r'NotificationStats', 'pending'),
            sent: BuiltValueNullFieldError.checkNotNull(
                sent, r'NotificationStats', 'sent'),
            failed: BuiltValueNullFieldError.checkNotNull(
                failed, r'NotificationStats', 'failed'),
            cancelled: BuiltValueNullFieldError.checkNotNull(
                cancelled, r'NotificationStats', 'cancelled'),
            byType: byType.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'byType';
        byType.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'NotificationStats', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
