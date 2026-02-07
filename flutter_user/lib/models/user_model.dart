class User {
  final String email;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? lastActive;
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.email,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.isActive = true,
    this.isSuperuser = false,
    this.lastActive,
    required this.id,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    String? avatar = json['avatar_url'] ?? json['avatarUrl'];
    String? nick = json['nickname'] ?? json['nickName'];
    bool active = json['is_active'] ?? json['isActive'] ?? true;
    bool superuser = json['is_superuser'] ?? json['isSuperuser'] ?? false;

    return User(
      email: json['email'] as String,
      username: json['username'] as String,
      nickname: nick,
      avatarUrl: avatar,
      isActive: active,
      isSuperuser: superuser,
      lastActive: _parseDateTime(json['last_active'] ?? json['lastActive']),
      id: (json['id'] is int) ? json['id'] as int : int.parse('${json['id']}'),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'is_superuser': isSuperuser,
    'last_active': lastActive?.toIso8601String(),
    'id': id,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
