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
  final int? priority;
  @override
  final int? messageId;

  factory _$NotificationCreate(
          [void Function(NotificationCreateBuilder)? updates]) =>
      (NotificationCreateBuilder()..update(updates))._build();

  _$NotificationCreate._(
      {required this.title,
      required this.content,
      this.priority,
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
        priority == other.priority &&
        messageId == other.messageId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationCreate')
          ..add('title', title)
          ..add('content', content)
          ..add('priority', priority)
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

  int? _priority;
  int? get priority => _$this._priority;
  set priority(int? priority) => _$this._priority = priority;

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
      _priority = $v.priority;
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
    final _$result = _$v ??
        _$NotificationCreate._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'NotificationCreate', 'title'),
          content: BuiltValueNullFieldError.checkNotNull(
              content, r'NotificationCreate', 'content'),
          priority: priority,
          messageId: messageId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
