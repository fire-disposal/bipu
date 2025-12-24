//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_schemas_notification_notification_status.g.dart';

class AppSchemasNotificationNotificationStatus extends EnumClass {

  /// 站内信状态
  @BuiltValueEnumConst(wireName: r'unread')
  static const AppSchemasNotificationNotificationStatus unread = _$unread;
  /// 站内信状态
  @BuiltValueEnumConst(wireName: r'read')
  static const AppSchemasNotificationNotificationStatus read = _$read;
  /// 站内信状态
  @BuiltValueEnumConst(wireName: r'deleted')
  static const AppSchemasNotificationNotificationStatus deleted = _$deleted;

  static Serializer<AppSchemasNotificationNotificationStatus> get serializer => _$appSchemasNotificationNotificationStatusSerializer;

  const AppSchemasNotificationNotificationStatus._(String name): super(name);

  static BuiltSet<AppSchemasNotificationNotificationStatus> get values => _$values;
  static AppSchemasNotificationNotificationStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AppSchemasNotificationNotificationStatusMixin = Object with _$AppSchemasNotificationNotificationStatusMixin;

