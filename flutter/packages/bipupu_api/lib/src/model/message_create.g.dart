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
  final AppModelsMessageMessageType messageType;
  @override
  final int? priority;
  @override
  final int? deviceId;
  @override
  final BuiltMap<String, JsonObject?>? pattern;
  @override
  final int? senderId;
  @override
  final int? receiverId;

  factory _$MessageCreate([void Function(MessageCreateBuilder)? updates]) =>
      (MessageCreateBuilder()..update(updates))._build();

  _$MessageCreate._(
      {required this.title,
      required this.content,
      required this.messageType,
      this.priority,
      this.deviceId,
      this.pattern,
      this.senderId,
      this.receiverId})
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
        deviceId == other.deviceId &&
        pattern == other.pattern &&
        senderId == other.senderId &&
        receiverId == other.receiverId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, messageType.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jc(_$hash, pattern.hashCode);
    _$hash = $jc(_$hash, senderId.hashCode);
    _$hash = $jc(_$hash, receiverId.hashCode);
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
          ..add('deviceId', deviceId)
          ..add('pattern', pattern)
          ..add('senderId', senderId)
          ..add('receiverId', receiverId))
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

  AppModelsMessageMessageType? _messageType;
  AppModelsMessageMessageType? get messageType => _$this._messageType;
  set messageType(AppModelsMessageMessageType? messageType) =>
      _$this._messageType = messageType;

  int? _priority;
  int? get priority => _$this._priority;
  set priority(int? priority) => _$this._priority = priority;

  int? _deviceId;
  int? get deviceId => _$this._deviceId;
  set deviceId(int? deviceId) => _$this._deviceId = deviceId;

  MapBuilder<String, JsonObject?>? _pattern;
  MapBuilder<String, JsonObject?> get pattern =>
      _$this._pattern ??= MapBuilder<String, JsonObject?>();
  set pattern(MapBuilder<String, JsonObject?>? pattern) =>
      _$this._pattern = pattern;

  int? _senderId;
  int? get senderId => _$this._senderId;
  set senderId(int? senderId) => _$this._senderId = senderId;

  int? _receiverId;
  int? get receiverId => _$this._receiverId;
  set receiverId(int? receiverId) => _$this._receiverId = receiverId;

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
      _pattern = $v.pattern?.toBuilder();
      _senderId = $v.senderId;
      _receiverId = $v.receiverId;
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
    _$MessageCreate _$result;
    try {
      _$result = _$v ??
          _$MessageCreate._(
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'MessageCreate', 'title'),
            content: BuiltValueNullFieldError.checkNotNull(
                content, r'MessageCreate', 'content'),
            messageType: BuiltValueNullFieldError.checkNotNull(
                messageType, r'MessageCreate', 'messageType'),
            priority: priority,
            deviceId: deviceId,
            pattern: _pattern?.build(),
            senderId: senderId,
            receiverId: receiverId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'pattern';
        _pattern?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MessageCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
