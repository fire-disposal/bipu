//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_stats.g.dart';

/// 消息统计信息
///
/// Properties:
/// * [total]
/// * [unread]
/// * [read]
/// * [archived]
/// * [byType]
@BuiltValue()
abstract class MessageStats
    implements Built<MessageStats, MessageStatsBuilder> {
  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'unread')
  int get unread;

  @BuiltValueField(wireName: r'read')
  int get read;

  @BuiltValueField(wireName: r'archived')
  int get archived;

  @BuiltValueField(wireName: r'by_type')
  BuiltMap<String, JsonObject?> get byType;

  MessageStats._();

  factory MessageStats([void updates(MessageStatsBuilder b)]) = _$MessageStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageStats> get serializer => _$MessageStatsSerializer();
}

class _$MessageStatsSerializer implements PrimitiveSerializer<MessageStats> {
  @override
  final Iterable<Type> types = const [MessageStats, _$MessageStats];

  @override
  final String wireName = r'MessageStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    yield r'unread';
    yield serializers.serialize(
      object.unread,
      specifiedType: const FullType(int),
    );
    yield r'read';
    yield serializers.serialize(
      object.read,
      specifiedType: const FullType(int),
    );
    yield r'archived';
    yield serializers.serialize(
      object.archived,
      specifiedType: const FullType(int),
    );
    yield r'by_type';
    yield serializers.serialize(
      object.byType,
      specifiedType: const FullType(
          BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'unread':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.unread = valueDes;
          break;
        case r'read':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.read = valueDes;
          break;
        case r'archived':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.archived = valueDes;
          break;
        case r'by_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
                BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.byType.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageStatsBuilder();
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
