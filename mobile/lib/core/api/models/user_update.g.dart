// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserUpdate _$UserUpdateFromJson(Map<String, dynamic> json) => UserUpdate(
  nickname: json['nickname'] as String?,
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
);

Map<String, dynamic> _$UserUpdateToJson(UserUpdate instance) =>
    <String, dynamic>{
      'nickname': instance.nickname,
      'birthday': instance.birthday?.toIso8601String(),
      'zodiac': instance.zodiac,
      'age': instance.age,
      'bazi': instance.bazi,
      'gender': _$GenderEnumMap[instance.gender],
      'mbti': instance.mbti,
      'birth_time': instance.birthTime,
      'birthplace': instance.birthplace,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.other: 'other',
  Gender.$unknown: r'$unknown',
};
