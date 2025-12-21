// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationResponse extends NotificationResponse {
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
  @override
  final int id;
  @override
  final int userId;
  @override
  final AppSchemasNotificationNotificationStatus status;
  @override
  final int retryCount;
  @override
  final int maxRetries;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? sentAt;
  @override
  final String? result;
  @override
  final String? errorMessage;

  factory _$NotificationResponse(
          [void Function(NotificationResponseBuilder)? updates]) =>
      (NotificationResponseBuilder()..update(updates))._build();

  _$NotificationResponse._(
      {required this.title,
      required this.content,
      required this.notificationType,
      this.priority,
      required this.target,
      this.config,
      this.scheduledAt,
      this.messageId,
      required this.id,
      required this.userId,
      required this.status,
      required this.retryCount,
      required this.maxRetries,
      required this.createdAt,
      this.updatedAt,
      this.sentAt,
      this.result,
      this.errorMessage})
      : super._();
  @override
  NotificationResponse rebuild(
          void Function(NotificationResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationResponseBuilder toBuilder() =>
      NotificationResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationResponse &&
        title == other.title &&
        content == other.content &&
        notificationType == other.notificationType &&
        priority == other.priority &&
        target == other.target &&
        config == other.config &&
        scheduledAt == other.scheduledAt &&
        messageId == other.messageId &&
        id == other.id &&
        userId == other.userId &&
        status == other.status &&
        retryCount == other.retryCount &&
        maxRetries == other.maxRetries &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        sentAt == other.sentAt &&
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
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, config.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, retryCount.hashCode);
    _$hash = $jc(_$hash, maxRetries.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, sentAt.hashCode);
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationResponse')
          ..add('title', title)
          ..add('content', content)
          ..add('notificationType', notificationType)
          ..add('priority', priority)
          ..add('target', target)
          ..add('config', config)
          ..add('scheduledAt', scheduledAt)
          ..add('messageId', messageId)
          ..add('id', id)
          ..add('userId', userId)
          ..add('status', status)
          ..add('retryCount', retryCount)
          ..add('maxRetries', maxRetries)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('sentAt', sentAt)
          ..add('result', result)
          ..add('errorMessage', errorMessage))
        .toString();
  }
}

class NotificationResponseBuilder
    implements Builder<NotificationResponse, NotificationResponseBuilder> {
  _$NotificationResponse? _$v;

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

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  AppSchemasNotificationNotificationStatus? _status;
  AppSchemasNotificationNotificationStatus? get status => _$this._status;
  set status(AppSchemasNotificationNotificationStatus? status) =>
      _$this._status = status;

  int? _retryCount;
  int? get retryCount => _$this._retryCount;
  set retryCount(int? retryCount) => _$this._retryCount = retryCount;

  int? _maxRetries;
  int? get maxRetries => _$this._maxRetries;
  set maxRetries(int? maxRetries) => _$this._maxRetries = maxRetries;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DateTime? _sentAt;
  DateTime? get sentAt => _$this._sentAt;
  set sentAt(DateTime? sentAt) => _$this._sentAt = sentAt;

  String? _result;
  String? get result => _$this._result;
  set result(String? result) => _$this._result = result;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  NotificationResponseBuilder() {
    NotificationResponse._defaults(this);
  }

  NotificationResponseBuilder get _$this {
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
      _id = $v.id;
      _userId = $v.userId;
      _status = $v.status;
      _retryCount = $v.retryCount;
      _maxRetries = $v.maxRetries;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _sentAt = $v.sentAt;
      _result = $v.result;
      _errorMessage = $v.errorMessage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationResponse other) {
    _$v = other as _$NotificationResponse;
  }

  @override
  void update(void Function(NotificationResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationResponse build() => _build();

  _$NotificationResponse _build() {
    _$NotificationResponse _$result;
    try {
      _$result = _$v ??
          _$NotificationResponse._(
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'NotificationResponse', 'title'),
            content: BuiltValueNullFieldError.checkNotNull(
                content, r'NotificationResponse', 'content'),
            notificationType: BuiltValueNullFieldError.checkNotNull(
                notificationType, r'NotificationResponse', 'notificationType'),
            priority: priority,
            target: BuiltValueNullFieldError.checkNotNull(
                target, r'NotificationResponse', 'target'),
            config: _config?.build(),
            scheduledAt: scheduledAt,
            messageId: messageId,
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'NotificationResponse', 'id'),
            userId: BuiltValueNullFieldError.checkNotNull(
                userId, r'NotificationResponse', 'userId'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'NotificationResponse', 'status'),
            retryCount: BuiltValueNullFieldError.checkNotNull(
                retryCount, r'NotificationResponse', 'retryCount'),
            maxRetries: BuiltValueNullFieldError.checkNotNull(
                maxRetries, r'NotificationResponse', 'maxRetries'),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'NotificationResponse', 'createdAt'),
            updatedAt: updatedAt,
            sentAt: sentAt,
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
            r'NotificationResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
