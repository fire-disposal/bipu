import 'dart:convert';

class UserUpdateRequest {
  final String? nickname;
  final String? password;
  final String? username;

  // CosmicProfile字段 - 直接作为用户字段
  final DateTime? birthday;
  final String? zodiac;
  final int? age;
  final String? bazi;
  final String? gender;
  final String? mbti;
  final String? birthTime;
  final String? birthplace;

  UserUpdateRequest({
    this.nickname,
    this.password,
    this.username,
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

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    // 解析日期字段
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

    return UserUpdateRequest(
      nickname: json['nickname'] as String?,
      password: json['password'] as String?,
      username: json['username'] as String?,
      // CosmicProfile字段
      birthday: parseDate(json['birthday']),
      zodiac: json['zodiac'] as String?,
      age: (json['age'] is int)
          ? json['age'] as int
          : (json['age'] != null ? int.tryParse('${json['age']}') : null),
      bazi: json['bazi'] as String?,
      gender: json['gender'] as String?,
      mbti: json['mbti'] as String?,
      birthTime: json['birth_time'] as String?,
      birthplace: json['birthplace'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (nickname != null) data['nickname'] = nickname;
    if (password != null) data['password'] = password;
    if (username != null) data['username'] = username;

    // CosmicProfile字段
    if (birthday != null)
      data['birthday'] = birthday!.toIso8601String().split('T')[0];
    if (zodiac != null) data['zodiac'] = zodiac;
    if (age != null) data['age'] = age;
    if (bazi != null) data['bazi'] = bazi;
    if (gender != null) data['gender'] = gender;
    if (mbti != null) data['mbti'] = mbti;
    if (birthTime != null) data['birth_time'] = birthTime;
    if (birthplace != null) data['birthplace'] = birthplace;

    return data;
  }
}
