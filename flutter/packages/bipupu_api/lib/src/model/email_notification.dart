//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'email_notification.g.dart';

/// 邮件通知模式
///
/// Properties:
/// * [toEmail]
/// * [subject]
/// * [body]
/// * [htmlBody]
@BuiltValue()
abstract class EmailNotification
    implements Built<EmailNotification, EmailNotificationBuilder> {
  @BuiltValueField(wireName: r'to_email')
  String get toEmail;

  @BuiltValueField(wireName: r'subject')
  String get subject;

  @BuiltValueField(wireName: r'body')
  String get body;

  @BuiltValueField(wireName: r'html_body')
  String? get htmlBody;

  EmailNotification._();

  factory EmailNotification([void updates(EmailNotificationBuilder b)]) =
      _$EmailNotification;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EmailNotificationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EmailNotification> get serializer =>
      _$EmailNotificationSerializer();
}

class _$EmailNotificationSerializer
    implements PrimitiveSerializer<EmailNotification> {
  @override
  final Iterable<Type> types = const [EmailNotification, _$EmailNotification];

  @override
  final String wireName = r'EmailNotification';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EmailNotification object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'to_email';
    yield serializers.serialize(
      object.toEmail,
      specifiedType: const FullType(String),
    );
    yield r'subject';
    yield serializers.serialize(
      object.subject,
      specifiedType: const FullType(String),
    );
    yield r'body';
    yield serializers.serialize(
      object.body,
      specifiedType: const FullType(String),
    );
    if (object.htmlBody != null) {
      yield r'html_body';
      yield serializers.serialize(
        object.htmlBody,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EmailNotification object, {
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
    required EmailNotificationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'to_email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.toEmail = valueDes;
          break;
        case r'subject':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subject = valueDes;
          break;
        case r'body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.body = valueDes;
          break;
        case r'html_body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.htmlBody = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EmailNotification deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EmailNotificationBuilder();
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
