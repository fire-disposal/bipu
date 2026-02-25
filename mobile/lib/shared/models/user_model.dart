import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// 宇宙档案（匹配后端 CosmicProfile）
@JsonSerializable()
class CosmicProfile {
  /// 生日（公历）
  @JsonKey(name: 'birthday', fromJson: _parseDate, toJson: _formatDate)
  final DateTime? birthday;

  /// 星座
  final String? zodiac;

  /// 年龄
  final int? age;

  /// 生辰八字
  final String? bazi;

  /// 性别
  final String? gender;

  /// MBTI 类型
  final String? mbti;

  /// 出生时间
  final String? birthTime;

  /// 出生地
  final String? birthplace;

  CosmicProfile({
    this.birthday,
    this.zodiac,
    this.age,
    this.bazi,
    this.gender,
    this.mbti,
    this.birthTime,
    this.birthplace,
  });

  factory CosmicProfile.fromJson(Map<String, dynamic> json) =>
      _$CosmicProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CosmicProfileToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CosmicProfile &&
          runtimeType == other.runtimeType &&
          birthday == other.birthday &&
          zodiac == other.zodiac &&
          age == other.age &&
          bazi == other.bazi &&
          gender == other.gender &&
          mbti == other.mbti &&
          birthTime == other.birthTime &&
          birthplace == other.birthplace;

  @override
  int get hashCode =>
      birthday.hashCode ^
      zodiac.hashCode ^
      age.hashCode ^
      bazi.hashCode ^
      gender.hashCode ^
      mbti.hashCode ^
      birthTime.hashCode ^
      birthplace.hashCode;

  @override
  String toString() {
    return 'CosmicProfile(birthday: $birthday, zodiac: $zodiac, age: $age, bazi: $bazi, gender: $gender, mbti: $mbti, birthTime: $birthTime, birthplace: $birthplace)';
  }
}

/// 用户实体模型（匹配后端 UserResponse）
@JsonSerializable()
class UserModel {
  /// 用户 ID（数据库主键）
  final int id;

  /// 用户名
  final String username;

  /// Bipupu ID（唯一标识）
  @JsonKey(name: 'bipupu_id')
  final String bipupuId;

  /// 昵称
  final String? nickname;

  /// 头像 URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 宇宙档案
  @JsonKey(name: 'cosmic_profile')
  final CosmicProfile? cosmicProfile;

  /// 是否活跃
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// 是否超级用户
  @JsonKey(name: 'is_superuser')
  final bool isSuperuser;

  /// 最后活跃时间
  @JsonKey(
    name: 'last_active',
    fromJson: _parseDateTime,
    toJson: _formatDateTime,
  )
  final DateTime? lastActive;

  /// 创建时间
  @JsonKey(
    name: 'created_at',
    fromJson: _parseDateTimeRequired,
    toJson: _formatDateTime,
  )
  final DateTime createdAt;

  /// 更新时间
  @JsonKey(
    name: 'updated_at',
    fromJson: _parseDateTime,
    toJson: _formatDateTime,
  )
  final DateTime? updatedAt;

  /// 时区（后端可能不返回此字段）
  final String? timezone;

  /// 头像版本号，用于缓存失效
  @JsonKey(name: 'avatar_version')
  final int avatarVersion;

  UserModel({
    required this.id,
    required this.username,
    required this.bipupuId,
    this.nickname,
    this.avatarUrl,
    this.cosmicProfile,
    this.isActive = true,
    this.isSuperuser = false,
    this.lastActive,
    required this.createdAt,
    this.updatedAt,
    this.timezone = 'Asia/Shanghai',
    this.avatarVersion = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          bipupuId == other.bipupuId &&
          nickname == other.nickname &&
          avatarUrl == other.avatarUrl &&
          cosmicProfile == other.cosmicProfile &&
          isActive == other.isActive &&
          isSuperuser == other.isSuperuser &&
          lastActive == other.lastActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          timezone == other.timezone &&
          avatarVersion == other.avatarVersion;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      bipupuId.hashCode ^
      nickname.hashCode ^
      avatarUrl.hashCode ^
      cosmicProfile.hashCode ^
      isActive.hashCode ^
      isSuperuser.hashCode ^
      lastActive.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      (timezone?.hashCode ?? 0) ^
      avatarVersion.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, bipupuId: $bipupuId, nickname: $nickname, avatarUrl: $avatarUrl, cosmicProfile: $cosmicProfile, isActive: $isActive, isSuperuser: $isSuperuser, lastActive: $lastActive, createdAt: $createdAt, updatedAt: $updatedAt, timezone: $timezone, avatarVersion: $avatarVersion)';
  }
}

/// 用户创建请求（匹配后端 UserCreate）
@JsonSerializable()
class UserCreate {
  final String username;
  final String password;
  final String? nickname;

  UserCreate({required this.username, required this.password, this.nickname});

  factory UserCreate.fromJson(Map<String, dynamic> json) =>
      _$UserCreateFromJson(json);
  Map<String, dynamic> toJson() => _$UserCreateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCreate &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          password == other.password &&
          nickname == other.nickname;

  @override
  int get hashCode => username.hashCode ^ password.hashCode ^ nickname.hashCode;

  @override
  String toString() =>
      'UserCreate(username: $username, password: ***, nickname: $nickname)';
}

/// 用户登录请求（匹配后端 UserLogin）
@JsonSerializable()
class UserLogin {
  final String username;
  final String password;

  UserLogin({required this.username, required this.password});

  factory UserLogin.fromJson(Map<String, dynamic> json) =>
      _$UserLoginFromJson(json);
  Map<String, dynamic> toJson() => _$UserLoginToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLogin &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode => username.hashCode ^ password.hashCode;

  @override
  String toString() => 'UserLogin(username: $username, password: ***)';
}

/// 令牌响应（匹配后端 Token）
@JsonSerializable()
class Token {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  Token({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    required this.expiresIn,
  });

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
  Map<String, dynamic> toJson() => _$TokenToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          tokenType == other.tokenType &&
          expiresIn == other.expiresIn;

  @override
  int get hashCode =>
      accessToken.hashCode ^
      refreshToken.hashCode ^
      tokenType.hashCode ^
      expiresIn.hashCode;

  @override
  String toString() {
    return 'Token(accessToken: ***, refreshToken: ${refreshToken != null ? "***" : null}, tokenType: $tokenType, expiresIn: $expiresIn)';
  }
}

/// 令牌刷新请求（匹配后端 TokenRefresh）
@JsonSerializable()
class TokenRefresh {
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  TokenRefresh({required this.refreshToken});

  factory TokenRefresh.fromJson(Map<String, dynamic> json) =>
      _$TokenRefreshFromJson(json);
  Map<String, dynamic> toJson() => _$TokenRefreshToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenRefresh &&
          runtimeType == other.runtimeType &&
          refreshToken == other.refreshToken;

  @override
  int get hashCode => refreshToken.hashCode;

  @override
  String toString() => 'TokenRefresh(refreshToken: ***)';
}

/// 用户更新请求（匹配后端 UserUpdate）
@JsonSerializable()
class UserUpdate {
  final String? nickname;
  @JsonKey(name: 'cosmic_profile')
  final Map<String, dynamic>? cosmicProfile;

  UserUpdate({this.nickname, this.cosmicProfile});

  factory UserUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$UserUpdateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserUpdate &&
          runtimeType == other.runtimeType &&
          nickname == other.nickname &&
          cosmicProfile == other.cosmicProfile;

  @override
  int get hashCode => nickname.hashCode ^ cosmicProfile.hashCode;

  @override
  String toString() =>
      'UserUpdate(nickname: $nickname, cosmicProfile: $cosmicProfile)';
}

/// 密码更新请求（匹配后端 UserPasswordUpdate）
@JsonSerializable()
class UserPasswordUpdate {
  @JsonKey(name: 'old_password')
  final String oldPassword;
  @JsonKey(name: 'new_password')
  final String newPassword;

  UserPasswordUpdate({required this.oldPassword, required this.newPassword});

  factory UserPasswordUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserPasswordUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$UserPasswordUpdateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPasswordUpdate &&
          runtimeType == other.runtimeType &&
          oldPassword == other.oldPassword &&
          newPassword == other.newPassword;

  @override
  int get hashCode => oldPassword.hashCode ^ newPassword.hashCode;

  @override
  String toString() => 'UserPasswordUpdate(oldPassword: ***, newPassword: ***)';
}

// --- 日期处理辅助函数 ---

DateTime? _parseDate(dynamic value) => _commonDateParse(value);

String? _formatDate(DateTime? value) {
  if (value == null) return null;
  return value.toIso8601String().split('T').first;
}

DateTime? _parseDateTime(dynamic value) => _commonDateParse(value);

DateTime _parseDateTimeRequired(dynamic value) {
  return _commonDateParse(value) ?? DateTime.now();
}

String? _formatDateTime(DateTime? value) => value?.toIso8601String();

/// 通用日期解析，增加容错性
DateTime? _commonDateParse(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
