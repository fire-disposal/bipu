// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_log_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminLogResponse extends AdminLogResponse {
  @override
  final int adminId;
  @override
  final String action;
  @override
  final BuiltMap<String, JsonObject?>? detail;
  @override
  final DateTime? timestamp;
  @override
  final int id;

  factory _$AdminLogResponse(
          [void Function(AdminLogResponseBuilder)? updates]) =>
      (AdminLogResponseBuilder()..update(updates))._build();

  _$AdminLogResponse._(
      {required this.adminId,
      required this.action,
      this.detail,
      this.timestamp,
      required this.id})
      : super._();
  @override
  AdminLogResponse rebuild(void Function(AdminLogResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminLogResponseBuilder toBuilder() =>
      AdminLogResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminLogResponse &&
        adminId == other.adminId &&
        action == other.action &&
        detail == other.detail &&
        timestamp == other.timestamp &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adminId.hashCode);
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, detail.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminLogResponse')
          ..add('adminId', adminId)
          ..add('action', action)
          ..add('detail', detail)
          ..add('timestamp', timestamp)
          ..add('id', id))
        .toString();
  }
}

class AdminLogResponseBuilder
    implements Builder<AdminLogResponse, AdminLogResponseBuilder> {
  _$AdminLogResponse? _$v;

  int? _adminId;
  int? get adminId => _$this._adminId;
  set adminId(int? adminId) => _$this._adminId = adminId;

  String? _action;
  String? get action => _$this._action;
  set action(String? action) => _$this._action = action;

  MapBuilder<String, JsonObject?>? _detail;
  MapBuilder<String, JsonObject?> get detail =>
      _$this._detail ??= MapBuilder<String, JsonObject?>();
  set detail(MapBuilder<String, JsonObject?>? detail) =>
      _$this._detail = detail;

  DateTime? _timestamp;
  DateTime? get timestamp => _$this._timestamp;
  set timestamp(DateTime? timestamp) => _$this._timestamp = timestamp;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  AdminLogResponseBuilder() {
    AdminLogResponse._defaults(this);
  }

  AdminLogResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adminId = $v.adminId;
      _action = $v.action;
      _detail = $v.detail?.toBuilder();
      _timestamp = $v.timestamp;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminLogResponse other) {
    _$v = other as _$AdminLogResponse;
  }

  @override
  void update(void Function(AdminLogResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminLogResponse build() => _build();

  _$AdminLogResponse _build() {
    _$AdminLogResponse _$result;
    try {
      _$result = _$v ??
          _$AdminLogResponse._(
            adminId: BuiltValueNullFieldError.checkNotNull(
                adminId, r'AdminLogResponse', 'adminId'),
            action: BuiltValueNullFieldError.checkNotNull(
                action, r'AdminLogResponse', 'action'),
            detail: _detail?.build(),
            timestamp: timestamp,
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'AdminLogResponse', 'id'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'detail';
        _detail?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AdminLogResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
