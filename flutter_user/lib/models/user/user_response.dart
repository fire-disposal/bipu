class UserResponse {
  final String email;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? lastActive;
  final int id;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserResponse({
    required this.email,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.isActive = true,
    this.isSuperuser = false,
    this.lastActive,
    required this.id,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      email: json['email'] as String,
      username: json['username'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] ?? true,
      isSuperuser: json['isSuperuser'] ?? false,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
    'isActive': isActive,
    'isSuperuser': isSuperuser,
    'lastActive': lastActive?.toIso8601String(),
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
