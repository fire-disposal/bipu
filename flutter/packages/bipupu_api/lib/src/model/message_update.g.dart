// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageUpdate extends MessageUpdate {
  @override
  final String? title;
  @override
  final String? content;
  @override
  final AppSchemasMessageMessageType? messageType;
  @override
  final int? priority;
  @override
  final AppSchemasMessageMessageStatus? status;
  @override
  final bool? isRead;

  factory _$MessageUpdate([void Function(MessageUpdateBuilder)? updates]) =>
      (MessageUpdateBuilder()..update(updates))._build();

  _$MessageUpdate._(
      {this.title,
      this.content,
      this.messageType,
      this.priority,
      this.status,
      this.isRead})
      : super._();
  @override
  MessageUpdate rebuild(void Function(MessageUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageUpdateBuilder toBuilder() => MessageUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageUpdate &&
        title == other.title &&
        content == other.content &&
        messageType == other.messageType &&
        priority == other.priority &&
        status == other.status &&
        isRead == other.isRead;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, messageType.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, isRead.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageUpdate')
          ..add('title', title)
          ..add('content', content)
          ..add('messageType', messageType)
          ..add('priority', priority)
          ..add('status', status)
          ..add('isRead', isRead))
        .toString();
  }
}

class MessageUpdateBuilder
    implements Builder<MessageUpdate, MessageUpdateBuilder> {
  _$MessageUpdate? _$v;

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

  AppSchemasMessageMessageStatus? _status;
  AppSchemasMessageMessageStatus? get status => _$this._status;
  set status(AppSchemasMessageMessageStatus? status) => _$this._status = status;

  bool? _isRead;
  bool? get isRead => _$this._isRead;
  set isRead(bool? isRead) => _$this._isRead = isRead;

  MessageUpdateBuilder() {
    MessageUpdate._defaults(this);
  }

  MessageUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _messageType = $v.messageType;
      _priority = $v.priority;
      _status = $v.status;
      _isRead = $v.isRead;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageUpdate other) {
    _$v = other as _$MessageUpdate;
  }

  @override
  void update(void Function(MessageUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageUpdate build() => _build();

  _$MessageUpdate _build() {
    final _$result = _$v ??
        _$MessageUpdate._(
          title: title,
          content: content,
          messageType: messageType,
          priority: priority,
          status: status,
          isRead: isRead,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
