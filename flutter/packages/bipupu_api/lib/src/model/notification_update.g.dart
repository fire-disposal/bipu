// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationUpdate extends NotificationUpdate {
  @override
  final String? title;
  @override
  final String? content;
  @override
  final AppSchemasNotificationNotificationType? notificationType;
  @override
  final int? priority;
  @override
  final AppSchemasNotificationNotificationStatus? status;
  @override
  final String? target;
  @override
  final BuiltMap<String, JsonObject?>? config;
  @override
  final DateTime? scheduledAt;
  @override
  final int? retryCount;
  @override
  final String? result;
  @override
  final String? errorMessage;

  factory _$NotificationUpdate(
          [void Function(NotificationUpdateBuilder)? updates]) =>
      (NotificationUpdateBuilder()..update(updates))._build();

  _$NotificationUpdate._(
      {this.title,
      this.content,
      this.notificationType,
      this.priority,
      this.status,
      this.target,
      this.config,
      this.scheduledAt,
      this.retryCount,
      this.result,
      this.errorMessage})
      : super._();
  @override
  NotificationUpdate rebuild(
          void Function(NotificationUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationUpdateBuilder toBuilder() =>
      NotificationUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationUpdate &&
        title == other.title &&
        content == other.content &&
        notificationType == other.notificationType &&
        priority == other.priority &&
        status == other.status &&
        target == other.target &&
        config == other.config &&
        scheduledAt == other.scheduledAt &&
        retryCount == other.retryCount &&
        result == other.result &&
        errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, notificationType.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, config.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, retryCount.hashCode);
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationUpdate')
          ..add('title', title)
          ..add('content', content)
          ..add('notificationType', notificationType)
          ..add('priority', priority)
          ..add('status', status)
          ..add('target', target)
          ..add('config', config)
          ..add('scheduledAt', scheduledAt)
          ..add('retryCount', retryCount)
          ..add('result', result)
          ..add('errorMessage', errorMessage))
        .toString();
  }
}

class NotificationUpdateBuilder
    implements Builder<NotificationUpdate, NotificationUpdateBuilder> {
  _$NotificationUpdate? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  AppSchemasNotificationNotificationType? _notificationType;
  AppSchemasNotificationNotificationType? get notificationType =>
      _$this._notificationType;
  set notificationType(
          AppSchemasNotificationNotificationType? notificationType) =>
      _$this._notificationType = notificationType;

  int? _priority;
  int? get priority => _$this._priority;
  set priority(int? priority) => _$this._priority = priority;

  AppSchemasNotificationNotificationStatus? _status;
  AppSchemasNotificationNotificationStatus? get status => _$this._status;
  set status(AppSchemasNotificationNotificationStatus? status) =>
      _$this._status = status;

  String? _target;
  String? get target => _$this._target;
  set target(String? target) => _$this._target = target;

  MapBuilder<String, JsonObject?>? _config;
  MapBuilder<String, JsonObject?> get config =>
      _$this._config ??= MapBuilder<String, JsonObject?>();
  set config(MapBuilder<String, JsonObject?>? config) =>
      _$this._config = config;

  DateTime? _scheduledAt;
  DateTime? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(DateTime? scheduledAt) => _$this._scheduledAt = scheduledAt;

  int? _retryCount;
  int? get retryCount => _$this._retryCount;
  set retryCount(int? retryCount) => _$this._retryCount = retryCount;

  String? _result;
  String? get result => _$this._result;
  set result(String? result) => _$this._result = result;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  NotificationUpdateBuilder() {
    NotificationUpdate._defaults(this);
  }

  NotificationUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _notificationType = $v.notificationType;
      _priority = $v.priority;
      _status = $v.status;
      _target = $v.target;
      _config = $v.config?.toBuilder();
      _scheduledAt = $v.scheduledAt;
      _retryCount = $v.retryCount;
      _result = $v.result;
      _errorMessage = $v.errorMessage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationUpdate other) {
    _$v = other as _$NotificationUpdate;
  }

  @override
  void update(void Function(NotificationUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationUpdate build() => _build();

  _$NotificationUpdate _build() {
    _$NotificationUpdate _$result;
    try {
      _$result = _$v ??
          _$NotificationUpdate._(
            title: title,
            content: content,
            notificationType: notificationType,
            priority: priority,
            status: status,
            target: target,
            config: _config?.build(),
            scheduledAt: scheduledAt,
            retryCount: retryCount,
            result: result,
            errorMessage: errorMessage,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'config';
        _config?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'NotificationUpdate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
