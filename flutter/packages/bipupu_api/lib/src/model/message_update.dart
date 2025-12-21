//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/app_schemas_message_message_status.dart';
import 'package:openapi/src/model/app_schemas_message_message_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_update.g.dart';

/// 更新消息模式
///
/// Properties:
/// * [title]
/// * [content]
/// * [messageType]
/// * [priority]
/// * [status]
/// * [isRead]
@BuiltValue()
abstract class MessageUpdate
    implements Built<MessageUpdate, MessageUpdateBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'content')
  String? get content;

  @BuiltValueField(wireName: r'message_type')
  AppSchemasMessageMessageType? get messageType;
  // enum messageTypeEnum {  system,  device,  user,  alert,  notification,  };

  @BuiltValueField(wireName: r'priority')
  int? get priority;

  @BuiltValueField(wireName: r'status')
  AppSchemasMessageMessageStatus? get status;
  // enum statusEnum {  unread,  read,  archived,  };

  @BuiltValueField(wireName: r'is_read')
  bool? get isRead;

  MessageUpdate._();

  factory MessageUpdate([void updates(MessageUpdateBuilder b)]) =
      _$MessageUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageUpdate> get serializer =>
      _$MessageUpdateSerializer();
}

class _$MessageUpdateSerializer implements PrimitiveSerializer<MessageUpdate> {
  @override
  final Iterable<Type> types = const [MessageUpdate, _$MessageUpdate];

  @override
  final String wireName = r'MessageUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.content != null) {
      yield r'content';
      yield serializers.serialize(
        object.content,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.messageType != null) {
      yield r'message_type';
      yield serializers.serialize(
        object.messageType,
        specifiedType: const FullType.nullable(AppSchemasMessageMessageType),
      );
    }
    if (object.priority != null) {
      yield r'priority';
      yield serializers.serialize(
        object.priority,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(AppSchemasMessageMessageStatus),
      );
    }
    if (object.isRead != null) {
      yield r'is_read';
      yield serializers.serialize(
        object.isRead,
        specifiedType: const FullType.nullable(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageUpdate object, {
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
    required MessageUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.content = valueDes;
          break;
        case r'message_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType.nullable(AppSchemasMessageMessageType),
          ) as AppSchemasMessageMessageType?;
          if (valueDes == null) continue;
          result.messageType = valueDes;
          break;
        case r'priority':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.priority = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType.nullable(AppSchemasMessageMessageStatus),
          ) as AppSchemasMessageMessageStatus?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'is_read':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.isRead = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageUpdateBuilder();
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
