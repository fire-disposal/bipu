//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_ack_event_response.g.dart';

/// 消息回执事件响应模式
///
/// Properties:
/// * [messageId] - 消息ID
/// * [event] - 事件类型（delivered/displayed/deleted）
/// * [timestamp] - 事件时间
/// * [id] 
@BuiltValue()
abstract class MessageAckEventResponse implements Built<MessageAckEventResponse, MessageAckEventResponseBuilder> {
  /// 消息ID
  @BuiltValueField(wireName: r'message_id')
  int get messageId;

  /// 事件类型（delivered/displayed/deleted）
  @BuiltValueField(wireName: r'event')
  String get event;

  /// 事件时间
  @BuiltValueField(wireName: r'timestamp')
  DateTime? get timestamp;

  @BuiltValueField(wireName: r'id')
  int get id;

  MessageAckEventResponse._();

  factory MessageAckEventResponse([void updates(MessageAckEventResponseBuilder b)]) = _$MessageAckEventResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageAckEventResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageAckEventResponse> get serializer => _$MessageAckEventResponseSerializer();
}

class _$MessageAckEventResponseSerializer implements PrimitiveSerializer<MessageAckEventResponse> {
  @override
  final Iterable<Type> types = const [MessageAckEventResponse, _$MessageAckEventResponse];

  @override
  final String wireName = r'MessageAckEventResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageAckEventResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message_id';
    yield serializers.serialize(
      object.messageId,
      specifiedType: const FullType(int),
    );
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(String),
    );
    if (object.timestamp != null) {
      yield r'timestamp';
      yield serializers.serialize(
        object.timestamp,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageAckEventResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageAckEventResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.messageId = valueDes;
          break;
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.event = valueDes;
          break;
        case r'timestamp':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.timestamp = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageAckEventResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageAckEventResponseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

