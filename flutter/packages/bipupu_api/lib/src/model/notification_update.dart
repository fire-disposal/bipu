//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/app_schemas_notification_notification_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notification_update.g.dart';

/// 更新站内信模式
///
/// Properties:
/// * [title] 
/// * [content] 
/// * [priority] 
/// * [status] 
@BuiltValue()
abstract class NotificationUpdate implements Built<NotificationUpdate, NotificationUpdateBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'content')
  String? get content;

  @BuiltValueField(wireName: r'priority')
  int? get priority;

  @BuiltValueField(wireName: r'status')
  AppSchemasNotificationNotificationStatus? get status;
  // enum statusEnum {  unread,  read,  deleted,  };

  NotificationUpdate._();

  factory NotificationUpdate([void updates(NotificationUpdateBuilder b)]) = _$NotificationUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationUpdate> get serializer => _$NotificationUpdateSerializer();
}

class _$NotificationUpdateSerializer implements PrimitiveSerializer<NotificationUpdate> {
  @override
  final Iterable<Type> types = const [NotificationUpdate, _$NotificationUpdate];

  @override
  final String wireName = r'NotificationUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationUpdate object, {
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
        specifiedType: const FullType.nullable(AppSchemasNotificationNotificationStatus),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    NotificationUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationUpdateBuilder result,
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
            specifiedType: const FullType.nullable(AppSchemasNotificationNotificationStatus),
          ) as AppSchemasNotificationNotificationStatus?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotificationUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationUpdateBuilder();
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

