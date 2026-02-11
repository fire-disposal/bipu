class UserUpdateRequest {
  final String? email;
  final String? nickname;
  final String? password;
  final String? username;
  final Map<String, dynamic>? cosmicProfile;

  UserUpdateRequest({
    this.email,
    this.nickname,
    this.password,
    this.username,
    this.cosmicProfile,
  });

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequest(
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      password: json['password'] as String?,
      username: json['username'] as String?,
      cosmicProfile: json['cosmic_profile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'nickname': nickname,
    'password': password,
    'username': username,
    'cosmic_profile': cosmicProfile,
  };
}
