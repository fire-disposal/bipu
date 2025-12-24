//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/app_models_message_message_type.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_create.g.dart';

/// 创建消息模式
///
/// Properties:
/// * [title] 
/// * [content] 
/// * [messageType] 
/// * [priority] 
/// * [deviceId] 
/// * [pattern] 
/// * [senderId] 
/// * [receiverId] 
@BuiltValue()
abstract class MessageCreate implements Built<MessageCreate, MessageCreateBuilder> {
  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'content')
  String get content;

  @BuiltValueField(wireName: r'message_type')
  AppModelsMessageMessageType get messageType;
  // enum messageTypeEnum {  system,  device,  user,  alert,  notification,  };

  @BuiltValueField(wireName: r'priority')
  int? get priority;

  @BuiltValueField(wireName: r'device_id')
  int? get deviceId;

  @BuiltValueField(wireName: r'pattern')
  BuiltMap<String, JsonObject?>? get pattern;

  @BuiltValueField(wireName: r'sender_id')
  int? get senderId;

  @BuiltValueField(wireName: r'receiver_id')
  int? get receiverId;

  MessageCreate._();

  factory MessageCreate([void updates(MessageCreateBuilder b)]) = _$MessageCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageCreateBuilder b) => b
      ..priority = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageCreate> get serializer => _$MessageCreateSerializer();
}

class _$MessageCreateSerializer implements PrimitiveSerializer<MessageCreate> {
  @override
  final Iterable<Type> types = const [MessageCreate, _$MessageCreate];

  @override
  final String wireName = r'MessageCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'content';
    yield serializers.serialize(
      object.content,
      specifiedType: const FullType(String),
    );
    yield r'message_type';
    yield serializers.serialize(
      object.messageType,
      specifiedType: const FullType(AppModelsMessageMessageType),
    );
    if (object.priority != null) {
      yield r'priority';
      yield serializers.serialize(
        object.priority,
        specifiedType: const FullType(int),
      );
    }
    if (object.deviceId != null) {
      yield r'device_id';
      yield serializers.serialize(
        object.deviceId,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.pattern != null) {
      yield r'pattern';
      yield serializers.serialize(
        object.pattern,
        specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
    if (object.senderId != null) {
      yield r'sender_id';
      yield serializers.serialize(
        object.senderId,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.receiverId != null) {
      yield r'receiver_id';
      yield serializers.serialize(
        object.receiverId,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.content = valueDes;
          break;
        case r'message_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AppModelsMessageMessageType),
          ) as AppModelsMessageMessageType;
          result.messageType = valueDes;
          break;
        case r'priority':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.priority = valueDes;
          break;
        case r'device_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.deviceId = valueDes;
          break;
        case r'pattern':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>?;
          if (valueDes == null) continue;
          result.pattern.replace(valueDes);
          break;
        case r'sender_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.senderId = valueDes;
          break;
        case r'receiver_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.receiverId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageCreateBuilder();
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

