// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageResponse extends MessageResponse {
  @override
  final String title;
  @override
  final String content;
  @override
  final AppSchemasMessageMessageType messageType;
  @override
  final int? priority;
  @override
  final int? deviceId;
  @override
  final int id;
  @override
  final int userId;
  @override
  final AppSchemasMessageMessageStatus status;
  @override
  final bool isRead;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? readAt;

  factory _$MessageResponse([void Function(MessageResponseBuilder)? updates]) =>
      (MessageResponseBuilder()..update(updates))._build();

  _$MessageResponse._(
      {required this.title,
      required this.content,
      required this.messageType,
      this.priority,
      this.deviceId,
      required this.id,
      required this.userId,
      required this.status,
      required this.isRead,
      required this.createdAt,
      this.updatedAt,
      this.readAt})
      : super._();
  @override
  MessageResponse rebuild(void Function(MessageResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageResponseBuilder toBuilder() => MessageResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageResponse &&
        title == other.title &&
        content == other.content &&
        messageType == other.messageType &&
        priority == other.priority &&
        deviceId == other.deviceId &&
        id == other.id &&
        userId == other.userId &&
        status == other.status &&
        isRead == other.isRead &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        readAt == other.readAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, messageType.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, isRead.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, readAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageResponse')
          ..add('title', title)
          ..add('content', content)
          ..add('messageType', messageType)
          ..add('priority', priority)
          ..add('deviceId', deviceId)
          ..add('id', id)
          ..add('userId', userId)
          ..add('status', status)
          ..add('isRead', isRead)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('readAt', readAt))
        .toString();
  }
}

class MessageResponseBuilder
    implements Builder<MessageResponse, MessageResponseBuilder> {
  _$MessageResponse? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  AppSchemasMessageMessageType? _messageType;
  AppSchemasMessageMessageType? get messageType => _$this._messageType;
  set messageType(AppSchemasMessageMessageType? messageType) =>
      _$this._messageType = messageType;

  int? _priority;
  int? get priority => _$this._priority;
  set priority(int? priority) => _$this._priority = priority;

  int? _deviceId;
  int? get deviceId => _$this._deviceId;
  set deviceId(int? deviceId) => _$this._deviceId = deviceId;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  AppSchemasMessageMessageStatus? _status;
  AppSchemasMessageMessageStatus? get status => _$this._status;
  set status(AppSchemasMessageMessageStatus? status) => _$this._status = status;

  bool? _isRead;
  bool? get isRead => _$this._isRead;
  set isRead(bool? isRead) => _$this._isRead = isRead;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DateTime? _readAt;
  DateTime? get readAt => _$this._readAt;
  set readAt(DateTime? readAt) => _$this._readAt = readAt;

  MessageResponseBuilder() {
    MessageResponse._defaults(this);
  }

  MessageResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _messageType = $v.messageType;
      _priority = $v.priority;
      _deviceId = $v.deviceId;
      _id = $v.id;
      _userId = $v.userId;
      _status = $v.status;
      _isRead = $v.isRead;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _readAt = $v.readAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageResponse other) {
    _$v = other as _$MessageResponse;
  }

  @override
  void update(void Function(MessageResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageResponse build() => _build();

  _$MessageResponse _build() {
    final _$result = _$v ??
        _$MessageResponse._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'MessageResponse', 'title'),
          content: BuiltValueNullFieldError.checkNotNull(
              content, r'MessageResponse', 'content'),
          messageType: BuiltValueNullFieldError.checkNotNull(
              messageType, r'MessageResponse', 'messageType'),
          priority: priority,
          deviceId: deviceId,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'MessageResponse', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'MessageResponse', 'userId'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'MessageResponse', 'status'),
          isRead: BuiltValueNullFieldError.checkNotNull(
              isRead, r'MessageResponse', 'isRead'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'MessageResponse', 'createdAt'),
          updatedAt: updatedAt,
          readAt: readAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
