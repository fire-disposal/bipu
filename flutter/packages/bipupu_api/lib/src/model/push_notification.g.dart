// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notification.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PushNotification extends PushNotification {
  @override
  final String deviceToken;
  @override
  final String title;
  @override
  final String body;
  @override
  final BuiltMap<String, JsonObject?>? data;

  factory _$PushNotification(
          [void Function(PushNotificationBuilder)? updates]) =>
      (PushNotificationBuilder()..update(updates))._build();

  _$PushNotification._(
      {required this.deviceToken,
      required this.title,
      required this.body,
      this.data})
      : super._();
  @override
  PushNotification rebuild(void Function(PushNotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PushNotificationBuilder toBuilder() =>
      PushNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PushNotification &&
        deviceToken == other.deviceToken &&
        title == other.title &&
        body == other.body &&
        data == other.data;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PushNotification')
          ..add('deviceToken', deviceToken)
          ..add('title', title)
          ..add('body', body)
          ..add('data', data))
        .toString();
  }
}

class PushNotificationBuilder
    implements Builder<PushNotification, PushNotificationBuilder> {
  _$PushNotification? _$v;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  MapBuilder<String, JsonObject?>? _data;
  MapBuilder<String, JsonObject?> get data =>
      _$this._data ??= MapBuilder<String, JsonObject?>();
  set data(MapBuilder<String, JsonObject?>? data) => _$this._data = data;

  PushNotificationBuilder() {
    PushNotification._defaults(this);
  }

  PushNotificationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deviceToken = $v.deviceToken;
      _title = $v.title;
      _body = $v.body;
      _data = $v.data?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PushNotification other) {
    _$v = other as _$PushNotification;
  }

  @override
  void update(void Function(PushNotificationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PushNotification build() => _build();

  _$PushNotification _build() {
    _$PushNotification _$result;
    try {
      _$result = _$v ??
          _$PushNotification._(
            deviceToken: BuiltValueNullFieldError.checkNotNull(
                deviceToken, r'PushNotification', 'deviceToken'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'PushNotification', 'title'),
            body: BuiltValueNullFieldError.checkNotNull(
                body, r'PushNotification', 'body'),
            data: _data?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'data';
        _data?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PushNotification', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
