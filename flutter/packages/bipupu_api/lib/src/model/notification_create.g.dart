// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationCreate extends NotificationCreate {
  @override
  final String title;
  @override
  final String content;
  @override
  final AppSchemasNotificationNotificationType notificationType;
  @override
  final int? priority;
  @override
  final String target;
  @override
  final BuiltMap<String, JsonObject?>? config;
  @override
  final DateTime? scheduledAt;
  @override
  final int? messageId;

  factory _$NotificationCreate(
          [void Function(NotificationCreateBuilder)? updates]) =>
      (NotificationCreateBuilder()..update(updates))._build();

  _$NotificationCreate._(
      {required this.title,
      required this.content,
      required this.notificationType,
      this.priority,
      required this.target,
      this.config,
      this.scheduledAt,
      this.messageId})
      : super._();
  @override
  NotificationCreate rebuild(
          void Function(NotificationCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationCreateBuilder toBuilder() =>
      NotificationCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationCreate &&
        title == other.title &&
        content == other.content &&
        notificationType == other.notificationType &&
        priority == other.priority &&
        target == other.target &&
        config == other.config &&
        scheduledAt == other.scheduledAt &&
        messageId == other.messageId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, notificationType.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, config.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationCreate')
          ..add('title', title)
          ..add('content', content)
          ..add('notificationType', notificationType)
          ..add('priority', priority)
          ..add('target', target)
          ..add('config', config)
          ..add('scheduledAt', scheduledAt)
          ..add('messageId', messageId))
        .toString();
  }
}

class NotificationCreateBuilder
    implements Builder<NotificationCreate, NotificationCreateBuilder> {
  _$NotificationCreate? _$v;

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

  int? _messageId;
  int? get messageId => _$this._messageId;
  set messageId(int? messageId) => _$this._messageId = messageId;

  NotificationCreateBuilder() {
    NotificationCreate._defaults(this);
  }

  NotificationCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _notificationType = $v.notificationType;
      _priority = $v.priority;
      _target = $v.target;
      _config = $v.config?.toBuilder();
      _scheduledAt = $v.scheduledAt;
      _messageId = $v.messageId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationCreate other) {
    _$v = other as _$NotificationCreate;
  }

  @override
  void update(void Function(NotificationCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationCreate build() => _build();

  _$NotificationCreate _build() {
    _$NotificationCreate _$result;
    try {
      _$result = _$v ??
          _$NotificationCreate._(
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'NotificationCreate', 'title'),
            content: BuiltValueNullFieldError.checkNotNull(
                content, r'NotificationCreate', 'content'),
            notificationType: BuiltValueNullFieldError.checkNotNull(
                notificationType, r'NotificationCreate', 'notificationType'),
            priority: priority,
            target: BuiltValueNullFieldError.checkNotNull(
                target, r'NotificationCreate', 'target'),
            config: _config?.build(),
            scheduledAt: scheduledAt,
            messageId: messageId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'config';
        _config?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'NotificationCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
