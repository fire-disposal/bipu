//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_ack_event_create.g.dart';

/// 创建消息回执事件模式
///
/// Properties:
/// * [messageId] - 消息ID
/// * [event] - 事件类型（delivered/displayed/deleted）
/// * [timestamp] - 事件时间
@BuiltValue()
abstract class MessageAckEventCreate implements Built<MessageAckEventCreate, MessageAckEventCreateBuilder> {
  /// 消息ID
  @BuiltValueField(wireName: r'message_id')
  int get messageId;

  /// 事件类型（delivered/displayed/deleted）
  @BuiltValueField(wireName: r'event')
  String get event;

  /// 事件时间
  @BuiltValueField(wireName: r'timestamp')
  DateTime? get timestamp;

  MessageAckEventCreate._();

  factory MessageAckEventCreate([void updates(MessageAckEventCreateBuilder b)]) = _$MessageAckEventCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageAckEventCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageAckEventCreate> get serializer => _$MessageAckEventCreateSerializer();
}

class _$MessageAckEventCreateSerializer implements PrimitiveSerializer<MessageAckEventCreate> {
  @override
  final Iterable<Type> types = const [MessageAckEventCreate, _$MessageAckEventCreate];

  @override
  final String wireName = r'MessageAckEventCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageAckEventCreate object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageAckEventCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageAckEventCreateBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageAckEventCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageAckEventCreateBuilder();
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

