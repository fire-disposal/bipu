//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/app_schemas_friendship_friendship_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friendship_create.g.dart';

/// FriendshipCreate
///
/// Properties:
/// * [userId] 
/// * [friendId] 
/// * [status] 
@BuiltValue()
abstract class FriendshipCreate implements Built<FriendshipCreate, FriendshipCreateBuilder> {
  @BuiltValueField(wireName: r'user_id')
  int get userId;

  @BuiltValueField(wireName: r'friend_id')
  int get friendId;

  @BuiltValueField(wireName: r'status')
  AppSchemasFriendshipFriendshipStatus? get status;
  // enum statusEnum {  pending,  accepted,  blocked,  };

  FriendshipCreate._();

  factory FriendshipCreate([void updates(FriendshipCreateBuilder b)]) = _$FriendshipCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FriendshipCreateBuilder b) => b
      ..status = AppSchemasFriendshipFriendshipStatus.pending;

  @BuiltValueSerializer(custom: true)
  static Serializer<FriendshipCreate> get serializer => _$FriendshipCreateSerializer();
}

class _$FriendshipCreateSerializer implements PrimitiveSerializer<FriendshipCreate> {
  @override
  final Iterable<Type> types = const [FriendshipCreate, _$FriendshipCreate];

  @override
  final String wireName = r'FriendshipCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FriendshipCreate object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    FriendshipCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FriendshipCreateBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FriendshipCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FriendshipCreateBuilder();
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

