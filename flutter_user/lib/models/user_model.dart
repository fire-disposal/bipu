class User {
  final String?
  email; // Backend removed email, keeping nullable for compatibility if needed
  final String username;
  final String bipupuId; // Added bipupu_id
  final String? nickname;
  final String? avatarUrl;
  final bool isActive;
  final bool isSuperuser;
  final Map<String, dynamic>? cosmicProfile; // Added cosmic_profile
  final DateTime? lastActive;
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.email,
    required this.username,
    required this.bipupuId,
    this.nickname,
    this.avatarUrl,
    this.isActive = true,
    this.isSuperuser = false,
    this.cosmicProfile,
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
    // Handle bipupuId - fallback to empty string or throw if strictly required. Backend guarantees it.
    String bipId = json['bipupu_id'] ?? json['bipupuId'] ?? '';
    Map<String, dynamic>? cosmic =
        json['cosmic_profile'] ?? json['cosmicProfile'];

    return User(
      email: json['email'] as String?,
      username: json['username'] as String,
      bipupuId: bipId,
      nickname: nick,
      avatarUrl: avatar,
      isActive: active,
      isSuperuser: superuser,
      cosmicProfile: cosmic,
      lastActive: _parseDateTime(json['last_active'] ?? json['lastActive']),
      id: (json['id'] is int) ? json['id'] as int : int.parse('${json['id']}'),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'bipupu_id': bipupuId,
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'is_superuser': isSuperuser,
    'cosmic_profile': cosmicProfile,
    'last_active': lastActive?.toIso8601String(),
    'id': id,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
