class UserResponse {
  final int id;
  final String username;
  final String bipupuId;
  final String? nickname;
  final String? email;
  final String? avatarUrl;
  final Map<String, dynamic>? cosmicProfile;
  final bool isActive;
  final bool isSuperuser;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActive;

  UserResponse({
    required this.id,
    required this.username,
    required this.bipupuId,
    this.nickname,
    this.email,
    this.avatarUrl,
    this.cosmicProfile,
    this.isActive = true,
    this.isSuperuser = false,
    required this.createdAt,
    this.updatedAt,
    this.lastActive,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] ?? '',
      bipupuId: json['bipupu_id'] ?? '',
      nickname: json['nickname'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      cosmicProfile: json['cosmic_profile'],
      isActive: json['is_active'] == true,
      isSuperuser: json['is_superuser'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      lastActive: json['last_active'] != null
          ? DateTime.tryParse(json['last_active'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'bipupu_id': bipupuId,
    'nickname': nickname,
    'email': email,
    'avatar_url': avatarUrl,
    'cosmic_profile': cosmicProfile,
    'is_active': isActive,
    'is_superuser': isSuperuser,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'last_active': lastActive?.toIso8601String(),
  };
}
