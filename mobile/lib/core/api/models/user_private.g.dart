// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_private.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPrivate _$UserPrivateFromJson(Map<String, dynamic> json) => UserPrivate(
  username: json['username'] as String,
  bipupuId: json['bipupu_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isActive: json['is_active'] as bool? ?? true,
  avatarVersion: (json['avatar_version'] as num?)?.toInt() ?? 0,
  nickname: json['nickname'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  birthday: json['birthday'] == null
      ? null
      : DateTime.parse(json['birthday'] as String),
  zodiac: json['zodiac'] as String?,
  age: (json['age'] as num?)?.toInt(),
  bazi: json['bazi'] as String?,
  gender: json['gender'] == null
      ? null
      : Gender.fromJson(json['gender'] as String),
  mbti: json['mbti'] as String?,
  birthTime: json['birth_time'] as String?,
  birthplace: json['birthplace'] as String?,
  lastActive: json['last_active'] == null
      ? null
      : DateTime.parse(json['last_active'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserPrivateToJson(UserPrivate instance) =>
    <String, dynamic>{
      'username': instance.username,
      'bipupu_id': instance.bipupuId,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'birthday': instance.birthday?.toIso8601String(),
      'zodiac': instance.zodiac,
      'age': instance.age,
      'bazi': instance.bazi,
      'gender': _$GenderEnumMap[instance.gender],
      'mbti': instance.mbti,
      'birth_time': instance.birthTime,
      'birthplace': instance.birthplace,
      'last_active': instance.lastActive?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'avatar_version': instance.avatarVersion,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.other: 'other',
  Gender.$unknown: r'$unknown',
};
