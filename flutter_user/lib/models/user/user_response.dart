class UserResponse {
  final String email;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final bool isActive;
  final bool isSuperuser;
  final int id;

  UserResponse({
    required this.email,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.isActive = true,
    this.isSuperuser = false,
    required this.id,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      email: json['email'] is String
          ? json['email'] as String
          : throw FormatException('email is required and must be a string'),
      username: json['username'] is String
          ? json['username'] as String
          : throw FormatException('username is required and must be a string'),
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'] as String?,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isSuperuser: json['isSuperuser'] ?? json['is_superuser'] ?? false,
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
    'isActive': isActive,
    'isSuperuser': isSuperuser,
    'id': id,
  };
}
