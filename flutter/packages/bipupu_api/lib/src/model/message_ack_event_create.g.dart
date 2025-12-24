// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_ack_event_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageAckEventCreate extends MessageAckEventCreate {
  @override
  final int messageId;
  @override
  final String event;
  @override
  final DateTime? timestamp;

  factory _$MessageAckEventCreate(
          [void Function(MessageAckEventCreateBuilder)? updates]) =>
      (MessageAckEventCreateBuilder()..update(updates))._build();

  _$MessageAckEventCreate._(
      {required this.messageId, required this.event, this.timestamp})
      : super._();
  @override
  MessageAckEventCreate rebuild(
          void Function(MessageAckEventCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageAckEventCreateBuilder toBuilder() =>
      MessageAckEventCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageAckEventCreate &&
        messageId == other.messageId &&
        event == other.event &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageAckEventCreate')
          ..add('messageId', messageId)
          ..add('event', event)
          ..add('timestamp', timestamp))
        .toString();
  }
}

class MessageAckEventCreateBuilder
    implements Builder<MessageAckEventCreate, MessageAckEventCreateBuilder> {
  _$MessageAckEventCreate? _$v;

  int? _messageId;
  int? get messageId => _$this._messageId;
  set messageId(int? messageId) => _$this._messageId = messageId;

  String? _event;
  String? get event => _$this._event;
  set event(String? event) => _$this._event = event;

  DateTime? _timestamp;
  DateTime? get timestamp => _$this._timestamp;
  set timestamp(DateTime? timestamp) => _$this._timestamp = timestamp;

  MessageAckEventCreateBuilder() {
    MessageAckEventCreate._defaults(this);
  }

  MessageAckEventCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _messageId = $v.messageId;
      _event = $v.event;
      _timestamp = $v.timestamp;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageAckEventCreate other) {
    _$v = other as _$MessageAckEventCreate;
  }

  @override
  void update(void Function(MessageAckEventCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageAckEventCreate build() => _build();

  _$MessageAckEventCreate _build() {
    final _$result = _$v ??
        _$MessageAckEventCreate._(
          messageId: BuiltValueNullFieldError.checkNotNull(
              messageId, r'MessageAckEventCreate', 'messageId'),
          event: BuiltValueNullFieldError.checkNotNull(
              event, r'MessageAckEventCreate', 'event'),
          timestamp: timestamp,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
