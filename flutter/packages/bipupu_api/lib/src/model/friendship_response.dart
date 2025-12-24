//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/app_schemas_friendship_friendship_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friendship_response.g.dart';

/// FriendshipResponse
///
/// Properties:
/// * [userId] 
/// * [friendId] 
/// * [status] 
/// * [id] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class FriendshipResponse implements Built<FriendshipResponse, FriendshipResponseBuilder> {
  @BuiltValueField(wireName: r'user_id')
  int get userId;

  @BuiltValueField(wireName: r'friend_id')
  int get friendId;

  @BuiltValueField(wireName: r'status')
  AppSchemasFriendshipFriendshipStatus? get status;
  // enum statusEnum {  pending,  accepted,  blocked,  };

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime? get updatedAt;

  FriendshipResponse._();

  factory FriendshipResponse([void updates(FriendshipResponseBuilder b)]) = _$FriendshipResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FriendshipResponseBuilder b) => b
      ..status = AppSchemasFriendshipFriendshipStatus.pending;

  @BuiltValueSerializer(custom: true)
  static Serializer<FriendshipResponse> get serializer => _$FriendshipResponseSerializer();
}

class _$FriendshipResponseSerializer implements PrimitiveSerializer<FriendshipResponse> {
  @override
  final Iterable<Type> types = const [FriendshipResponse, _$FriendshipResponse];

  @override
  final String wireName = r'FriendshipResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FriendshipResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(int),
    );
    yield r'friend_id';
    yield serializers.serialize(
      object.friendId,
      specifiedType: const FullType(int),
    );
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(AppSchemasFriendshipFriendshipStatus),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    FriendshipResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FriendshipResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.userId = valueDes;
          break;
        case r'friend_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.friendId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AppSchemasFriendshipFriendshipStatus),
          ) as AppSchemasFriendshipFriendshipStatus;
          result.status = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FriendshipResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FriendshipResponseBuilder();
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

