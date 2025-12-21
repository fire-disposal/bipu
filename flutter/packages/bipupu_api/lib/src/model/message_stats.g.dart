// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageStats extends MessageStats {
  @override
  final int total;
  @override
  final int unread;
  @override
  final int read;
  @override
  final int archived;
  @override
  final BuiltMap<String, JsonObject?> byType;

  factory _$MessageStats([void Function(MessageStatsBuilder)? updates]) =>
      (MessageStatsBuilder()..update(updates))._build();

  _$MessageStats._(
      {required this.total,
      required this.unread,
      required this.read,
      required this.archived,
      required this.byType})
      : super._();
  @override
  MessageStats rebuild(void Function(MessageStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageStatsBuilder toBuilder() => MessageStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageStats &&
        total == other.total &&
        unread == other.unread &&
        read == other.read &&
        archived == other.archived &&
        byType == other.byType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, unread.hashCode);
    _$hash = $jc(_$hash, read.hashCode);
    _$hash = $jc(_$hash, archived.hashCode);
    _$hash = $jc(_$hash, byType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageStats')
          ..add('total', total)
          ..add('unread', unread)
          ..add('read', read)
          ..add('archived', archived)
          ..add('byType', byType))
        .toString();
  }
}

class MessageStatsBuilder
    implements Builder<MessageStats, MessageStatsBuilder> {
  _$MessageStats? _$v;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _unread;
  int? get unread => _$this._unread;
  set unread(int? unread) => _$this._unread = unread;

  int? _read;
  int? get read => _$this._read;
  set read(int? read) => _$this._read = read;

  int? _archived;
  int? get archived => _$this._archived;
  set archived(int? archived) => _$this._archived = archived;

  MapBuilder<String, JsonObject?>? _byType;
  MapBuilder<String, JsonObject?> get byType =>
      _$this._byType ??= MapBuilder<String, JsonObject?>();
  set byType(MapBuilder<String, JsonObject?>? byType) =>
      _$this._byType = byType;

  MessageStatsBuilder() {
    MessageStats._defaults(this);
  }

  MessageStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _unread = $v.unread;
      _read = $v.read;
      _archived = $v.archived;
      _byType = $v.byType.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageStats other) {
    _$v = other as _$MessageStats;
  }

  @override
  void update(void Function(MessageStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageStats build() => _build();

  _$MessageStats _build() {
    _$MessageStats _$result;
    try {
      _$result = _$v ??
          _$MessageStats._(
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'MessageStats', 'total'),
            unread: BuiltValueNullFieldError.checkNotNull(
                unread, r'MessageStats', 'unread'),
            read: BuiltValueNullFieldError.checkNotNull(
                read, r'MessageStats', 'read'),
            archived: BuiltValueNullFieldError.checkNotNull(
                archived, r'MessageStats', 'archived'),
            byType: byType.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'byType';
        byType.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MessageStats', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
