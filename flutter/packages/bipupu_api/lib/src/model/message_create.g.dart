// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageCreate extends MessageCreate {
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

  factory _$MessageCreate([void Function(MessageCreateBuilder)? updates]) =>
      (MessageCreateBuilder()..update(updates))._build();

  _$MessageCreate._(
      {required this.title,
      required this.content,
      required this.messageType,
      this.priority,
      this.deviceId})
      : super._();
  @override
  MessageCreate rebuild(void Function(MessageCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageCreateBuilder toBuilder() => MessageCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageCreate &&
        title == other.title &&
        content == other.content &&
        messageType == other.messageType &&
        priority == other.priority &&
        deviceId == other.deviceId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, messageType.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageCreate')
          ..add('title', title)
          ..add('content', content)
          ..add('messageType', messageType)
          ..add('priority', priority)
          ..add('deviceId', deviceId))
        .toString();
  }
}

class MessageCreateBuilder
    implements Builder<MessageCreate, MessageCreateBuilder> {
  _$MessageCreate? _$v;

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

  MessageCreateBuilder() {
    MessageCreate._defaults(this);
  }

  MessageCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _messageType = $v.messageType;
      _priority = $v.priority;
      _deviceId = $v.deviceId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageCreate other) {
    _$v = other as _$MessageCreate;
  }

  @override
  void update(void Function(MessageCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageCreate build() => _build();

  _$MessageCreate _build() {
    final _$result = _$v ??
        _$MessageCreate._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'MessageCreate', 'title'),
          content: BuiltValueNullFieldError.checkNotNull(
              content, r'MessageCreate', 'content'),
          messageType: BuiltValueNullFieldError.checkNotNull(
              messageType, r'MessageCreate', 'messageType'),
          priority: priority,
          deviceId: deviceId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
