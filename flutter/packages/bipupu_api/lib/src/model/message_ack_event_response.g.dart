// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_ack_event_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageAckEventResponse extends MessageAckEventResponse {
  @override
  final int messageId;
  @override
  final String event;
  @override
  final DateTime? timestamp;
  @override
  final int id;

  factory _$MessageAckEventResponse(
          [void Function(MessageAckEventResponseBuilder)? updates]) =>
      (MessageAckEventResponseBuilder()..update(updates))._build();

  _$MessageAckEventResponse._(
      {required this.messageId,
      required this.event,
      this.timestamp,
      required this.id})
      : super._();
  @override
  MessageAckEventResponse rebuild(
          void Function(MessageAckEventResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageAckEventResponseBuilder toBuilder() =>
      MessageAckEventResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageAckEventResponse &&
        messageId == other.messageId &&
        event == other.event &&
        timestamp == other.timestamp &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, messageId.hashCode);
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageAckEventResponse')
          ..add('messageId', messageId)
          ..add('event', event)
          ..add('timestamp', timestamp)
          ..add('id', id))
        .toString();
  }
}

class MessageAckEventResponseBuilder
    implements
        Builder<MessageAckEventResponse, MessageAckEventResponseBuilder> {
  _$MessageAckEventResponse? _$v;

  int? _messageId;
  int? get messageId => _$this._messageId;
  set messageId(int? messageId) => _$this._messageId = messageId;

  String? _event;
  String? get event => _$this._event;
  set event(String? event) => _$this._event = event;

  DateTime? _timestamp;
  DateTime? get timestamp => _$this._timestamp;
  set timestamp(DateTime? timestamp) => _$this._timestamp = timestamp;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  MessageAckEventResponseBuilder() {
    MessageAckEventResponse._defaults(this);
  }

  MessageAckEventResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _messageId = $v.messageId;
      _event = $v.event;
      _timestamp = $v.timestamp;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageAckEventResponse other) {
    _$v = other as _$MessageAckEventResponse;
  }

  @override
  void update(void Function(MessageAckEventResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageAckEventResponse build() => _build();

  _$MessageAckEventResponse _build() {
    final _$result = _$v ??
        _$MessageAckEventResponse._(
          messageId: BuiltValueNullFieldError.checkNotNull(
              messageId, r'MessageAckEventResponse', 'messageId'),
          event: BuiltValueNullFieldError.checkNotNull(
              event, r'MessageAckEventResponse', 'event'),
          timestamp: timestamp,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'MessageAckEventResponse', 'id'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
