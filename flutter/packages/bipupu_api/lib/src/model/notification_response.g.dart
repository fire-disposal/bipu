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
  final int? priority;
  @override
  final int? messageId;
  @override
  final int id;
  @override
  final int userId;
  @override
  final AppSchemasNotificationNotificationStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? readAt;

  factory _$NotificationResponse(
          [void Function(NotificationResponseBuilder)? updates]) =>
      (NotificationResponseBuilder()..update(updates))._build();

  _$NotificationResponse._(
      {required this.title,
      required this.content,
      this.priority,
      this.messageId,
      required this.id,
      required this.userId,
      required this.status,
      required this.createdAt,
      this.updatedAt,
      this.readAt})
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
        priority == other.priority &&
        messageId == other.messageId &&
        id == other.id &&
        userId == other.userId &&
        status == other.status &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        readAt == other.readAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, readAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationResponse')
          ..add('title', title)
          ..add('content', content)
          ..add('priority', priority)
          ..add('messageId', messageId)
          ..add('id', id)
          ..add('userId', userId)
          ..add('status', status)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('readAt', readAt))
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

  int? _priority;
  int? get priority => _$this._priority;
  set priority(int? priority) => _$this._priority = priority;

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

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DateTime? _readAt;
  DateTime? get readAt => _$this._readAt;
  set readAt(DateTime? readAt) => _$this._readAt = readAt;

  NotificationResponseBuilder() {
    NotificationResponse._defaults(this);
  }

  NotificationResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _priority = $v.priority;
      _messageId = $v.messageId;
      _id = $v.id;
      _userId = $v.userId;
      _status = $v.status;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _readAt = $v.readAt;
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
    final _$result = _$v ??
        _$NotificationResponse._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'NotificationResponse', 'title'),
          content: BuiltValueNullFieldError.checkNotNull(
              content, r'NotificationResponse', 'content'),
          priority: priority,
          messageId: messageId,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'NotificationResponse', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'NotificationResponse', 'userId'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'NotificationResponse', 'status'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'NotificationResponse', 'createdAt'),
          updatedAt: updatedAt,
          readAt: readAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
