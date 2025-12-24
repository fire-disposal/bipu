//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_profile.g.dart';

/// 用户详细资料模式
///
/// Properties:
/// * [id] 
/// * [username] 
/// * [email] 
/// * [nickname] 
/// * [fullName] 
/// * [isActive] 
/// * [isSuperuser] 
/// * [role] 
/// * [lastActive] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class UserProfile implements Built<UserProfile, UserProfileBuilder> {
  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'username')
  String get username;

  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'nickname')
  String? get nickname;

  @BuiltValueField(wireName: r'full_name')
  String? get fullName;

  @BuiltValueField(wireName: r'is_active')
  bool get isActive;

  @BuiltValueField(wireName: r'is_superuser')
  bool get isSuperuser;

  @BuiltValueField(wireName: r'role')
  String get role;

  @BuiltValueField(wireName: r'last_active')
  DateTime? get lastActive;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime? get updatedAt;

  UserProfile._();

  factory UserProfile([void updates(UserProfileBuilder b)]) = _$UserProfile;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserProfileBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserProfile> get serializer => _$UserProfileSerializer();
}

class _$UserProfileSerializer implements PrimitiveSerializer<UserProfile> {
  @override
  final Iterable<Type> types = const [UserProfile, _$UserProfile];

  @override
  final String wireName = r'UserProfile';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserProfile object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'username';
    yield serializers.serialize(
      object.username,
      specifiedType: const FullType(String),
    );
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'nickname';
    yield object.nickname == null ? null : serializers.serialize(
      object.nickname,
      specifiedType: const FullType.nullable(String),
    );
    yield r'full_name';
    yield object.fullName == null ? null : serializers.serialize(
      object.fullName,
      specifiedType: const FullType.nullable(String),
    );
    yield r'is_active';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    yield r'is_superuser';
    yield serializers.serialize(
      object.isSuperuser,
      specifiedType: const FullType(bool),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(String),
    );
    yield r'last_active';
    yield object.lastActive == null ? null : serializers.serialize(
      object.lastActive,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updated_at';
    yield object.updatedAt == null ? null : serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType.nullable(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UserProfile object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserProfileBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'username':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.username = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'nickname':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nickname = valueDes;
          break;
        case r'full_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.fullName = valueDes;
          break;
        case r'is_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'is_superuser':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isSuperuser = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.role = valueDes;
          break;
        case r'last_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastActive = valueDes;
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
  UserProfile deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserProfileBuilder();
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

