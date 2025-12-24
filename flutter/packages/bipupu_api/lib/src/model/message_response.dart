//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/app_models_message_message_type.dart';
import 'package:openapi/src/model/app_schemas_message_message_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_response.g.dart';

/// 消息响应模式
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
/// * [id] 
/// * [status] 
/// * [isRead] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [deliveredAt] 
/// * [readAt] 
@BuiltValue()
abstract class MessageResponse implements Built<MessageResponse, MessageResponseBuilder> {
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
  int get senderId;

  @BuiltValueField(wireName: r'receiver_id')
  int get receiverId;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'status')
  AppSchemasMessageMessageStatus get status;
  // enum statusEnum {  unread,  read,  archived,  };

  @BuiltValueField(wireName: r'is_read')
  bool get isRead;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime? get updatedAt;

  @BuiltValueField(wireName: r'delivered_at')
  DateTime? get deliveredAt;

  @BuiltValueField(wireName: r'read_at')
  DateTime? get readAt;

  MessageResponse._();

  factory MessageResponse([void updates(MessageResponseBuilder b)]) = _$MessageResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageResponseBuilder b) => b
      ..priority = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageResponse> get serializer => _$MessageResponseSerializer();
}

class _$MessageResponseSerializer implements PrimitiveSerializer<MessageResponse> {
  @override
  final Iterable<Type> types = const [MessageResponse, _$MessageResponse];

  @override
  final String wireName = r'MessageResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageResponse object, {
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
    yield r'sender_id';
    yield serializers.serialize(
      object.senderId,
      specifiedType: const FullType(int),
    );
    yield r'receiver_id';
    yield serializers.serialize(
      object.receiverId,
      specifiedType: const FullType(int),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(AppSchemasMessageMessageStatus),
    );
    yield r'is_read';
    yield serializers.serialize(
      object.isRead,
      specifiedType: const FullType(bool),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.updatedAt != null) {
      yield r'updated_at';
      yield serializers.serialize(
        object.updatedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.deliveredAt != null) {
      yield r'delivered_at';
      yield serializers.serialize(
        object.deliveredAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.readAt != null) {
      yield r'read_at';
      yield serializers.serialize(
        object.readAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageResponseBuilder result,
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
            specifiedType: const FullType(int),
          ) as int;
          result.senderId = valueDes;
          break;
        case r'receiver_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.receiverId = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AppSchemasMessageMessageStatus),
          ) as AppSchemasMessageMessageStatus;
          result.status = valueDes;
          break;
        case r'is_read':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isRead = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.updatedAt = valueDes;
          break;
        case r'delivered_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.deliveredAt = valueDes;
          break;
        case r'read_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.readAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageResponseBuilder();
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

