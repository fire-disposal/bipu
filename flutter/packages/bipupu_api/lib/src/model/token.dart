//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'token.g.dart';

/// 令牌响应模式
///
/// Properties:
/// * [accessToken] 
/// * [refreshToken] 
/// * [tokenType] 
/// * [expiresIn] 
/// * [user] 
@BuiltValue()
abstract class Token implements Built<Token, TokenBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String get accessToken;

  @BuiltValueField(wireName: r'refresh_token')
  String? get refreshToken;

  @BuiltValueField(wireName: r'token_type')
  String? get tokenType;

  @BuiltValueField(wireName: r'expires_in')
  int get expiresIn;

  @BuiltValueField(wireName: r'user')
  BuiltMap<String, JsonObject?>? get user;

  Token._();

  factory Token([void updates(TokenBuilder b)]) = _$Token;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TokenBuilder b) => b
      ..tokenType = 'bearer';

  @BuiltValueSerializer(custom: true)
  static Serializer<Token> get serializer => _$TokenSerializer();
}

class _$TokenSerializer implements PrimitiveSerializer<Token> {
  @override
  final Iterable<Type> types = const [Token, _$Token];

  @override
  final String wireName = r'Token';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Token object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'access_token';
    yield serializers.serialize(
      object.accessToken,
      specifiedType: const FullType(String),
    );
    if (object.refreshToken != null) {
      yield r'refresh_token';
      yield serializers.serialize(
        object.refreshToken,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.tokenType != null) {
      yield r'token_type';
      yield serializers.serialize(
        object.tokenType,
        specifiedType: const FullType(String),
      );
    }
    yield r'expires_in';
    yield serializers.serialize(
      object.expiresIn,
      specifiedType: const FullType(int),
    );
    if (object.user != null) {
      yield r'user';
      yield serializers.serialize(
        object.user,
        specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Token object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TokenBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessToken = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.refreshToken = valueDes;
          break;
        case r'token_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tokenType = valueDes;
          break;
        case r'expires_in':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.expiresIn = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>?;
          if (valueDes == null) continue;
          result.user.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Token deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TokenBuilder();
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

