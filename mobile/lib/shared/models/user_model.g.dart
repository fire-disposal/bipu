// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CosmicProfile _$CosmicProfileFromJson(Map<String, dynamic> json) =>
    CosmicProfile(
      birthday: _parseDate(json['birthday']),
      zodiac: json['zodiac'] as String?,
      age: (json['age'] as num?)?.toInt(),
      bazi: json['bazi'] as String?,
      gender: json['gender'] as String?,
      mbti: json['mbti'] as String?,
      birthTime: json['birthTime'] as String?,
      birthplace: json['birthplace'] as String?,
    );

Map<String, dynamic> _$CosmicProfileToJson(CosmicProfile instance) =>
    <String, dynamic>{
      'birthday': _formatDate(instance.birthday),
      'zodiac': instance.zodiac,
      'age': instance.age,
      'bazi': instance.bazi,
      'gender': instance.gender,
      'mbti': instance.mbti,
      'birthTime': instance.birthTime,
      'birthplace': instance.birthplace,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  bipupuId: json['bipupu_id'] as String,
  nickname: json['nickname'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  cosmicProfile: json['cosmic_profile'] == null
      ? null
      : CosmicProfile.fromJson(json['cosmic_profile'] as Map<String, dynamic>),
  isActive: json['is_active'] as bool? ?? true,
  isSuperuser: json['is_superuser'] as bool? ?? false,
  lastActive: _parseDateTime(json['last_active']),
  createdAt: _parseDateTimeRequired(json['created_at']),
  updatedAt: _parseDateTime(json['updated_at']),
  timezone: json['timezone'] as String? ?? 'Asia/Shanghai',
  avatarVersion: (json['avatar_version'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'bipupu_id': instance.bipupuId,
  'nickname': instance.nickname,
  'avatar_url': instance.avatarUrl,
  'cosmic_profile': instance.cosmicProfile,
  'is_active': instance.isActive,
  'is_superuser': instance.isSuperuser,
  'last_active': _formatDateTime(instance.lastActive),
  'created_at': _formatDateTime(instance.createdAt),
  'updated_at': _formatDateTime(instance.updatedAt),
  'timezone': instance.timezone,
  'avatar_version': instance.avatarVersion,
};

UserCreate _$UserCreateFromJson(Map<String, dynamic> json) => UserCreate(
  username: json['username'] as String,
  password: json['password'] as String,
  nickname: json['nickname'] as String?,
);

Map<String, dynamic> _$UserCreateToJson(UserCreate instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'nickname': instance.nickname,
    };

UserLogin _$UserLoginFromJson(Map<String, dynamic> json) => UserLogin(
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$UserLoginToJson(UserLogin instance) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
};

Token _$TokenFromJson(Map<String, dynamic> json) => Token(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String?,
  tokenType: json['token_type'] as String? ?? 'bearer',
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'token_type': instance.tokenType,
  'expires_in': instance.expiresIn,
};

TokenRefresh _$TokenRefreshFromJson(Map<String, dynamic> json) =>
    TokenRefresh(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$TokenRefreshToJson(TokenRefresh instance) =>
    <String, dynamic>{'refresh_token': instance.refreshToken};

UserUpdate _$UserUpdateFromJson(Map<String, dynamic> json) => UserUpdate(
  nickname: json['nickname'] as String?,
  cosmicProfile: json['cosmic_profile'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserUpdateToJson(UserUpdate instance) =>
    <String, dynamic>{
      'nickname': instance.nickname,
      'cosmic_profile': instance.cosmicProfile,
    };

UserPasswordUpdate _$UserPasswordUpdateFromJson(Map<String, dynamic> json) =>
    UserPasswordUpdate(
      oldPassword: json['old_password'] as String,
      newPassword: json['new_password'] as String,
    );

Map<String, dynamic> _$UserPasswordUpdateToJson(UserPasswordUpdate instance) =>
    <String, dynamic>{
      'old_password': instance.oldPassword,
      'new_password': instance.newPassword,
    };
