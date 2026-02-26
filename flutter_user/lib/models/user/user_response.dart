class UserResponse {
  final int id;
  final String username;
  final String bipupuId;
  final String? nickname;
  final String? avatarUrl;
  final bool isActive;
  final bool isSuperuser;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActive;
  final int avatarVersion;
  final String timezone;

  // CosmicProfile字段 - 直接作为用户字段
  final DateTime? birthday;
  final String? zodiac;
  final int? age;
  final String? bazi;
  final String? gender;
  final String? mbti;
  final String? birthTime;
  final String? birthplace;

  UserResponse({
    required this.id,
    required this.username,
    required this.bipupuId,
    this.nickname,
    this.avatarUrl,
    this.isActive = true,
    this.isSuperuser = false,
    required this.createdAt,
    this.updatedAt,
    this.lastActive,
    this.avatarVersion = 0,
    this.timezone = 'Asia/Shanghai',
    // CosmicProfile字段
    this.birthday,
    this.zodiac,
    this.age,
    this.bazi,
    this.gender,
    this.mbti,
    this.birthTime,
    this.birthplace,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    // 解析日期字段
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        // 尝试解析日期字符串，如 "1990-01-01"
        final date = DateTime.tryParse(value);
        if (date != null) return date;
        // 尝试添加时间部分
        return DateTime.tryParse('${value}T00:00:00Z');
      }
      return null;
    }

    return UserResponse(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] ?? '',
      bipupuId: json['bipupu_id'] ?? '',
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] == true,
      isSuperuser: json['is_superuser'] == true,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']),
      lastActive: parseDateTime(json['last_active']),
      avatarVersion: (json['avatar_version'] is int)
          ? json['avatar_version'] as int
          : int.tryParse('${json['avatar_version']}') ?? 0,
      timezone: json['timezone'] ?? 'Asia/Shanghai',
      // CosmicProfile字段
      birthday: parseDate(json['birthday']),
      zodiac: json['zodiac'],
      age: (json['age'] is int)
          ? json['age'] as int
          : (json['age'] != null ? int.tryParse('${json['age']}') : null),
      bazi: json['bazi'],
      gender: json['gender'],
      mbti: json['mbti'],
      birthTime: json['birth_time'],
      birthplace: json['birthplace'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'bipupu_id': bipupuId,
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'is_superuser': isSuperuser,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'last_active': lastActive?.toIso8601String(),
    'avatar_version': avatarVersion,
    'timezone': timezone,
    // CosmicProfile字段
    'birthday': birthday?.toIso8601String(),
    'zodiac': zodiac,
    'age': age,
    'bazi': bazi,
    'gender': gender,
    'mbti': mbti,
    'birth_time': birthTime,
    'birthplace': birthplace,
  };
}
