class UserUpdateRequest {
  final String? email;
  final String? nickname;
  final String? password;
  final String? username;

  UserUpdateRequest({this.email, this.nickname, this.password, this.username});

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequest(
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      password: json['password'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'nickname': nickname,
    'password': password,
    'username': username,
  };
}

class OnlineStatusUpdate {
  final bool isActive;

  OnlineStatusUpdate({required this.isActive});

  factory OnlineStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OnlineStatusUpdate(isActive: json['is_active'] as bool);
  }

  Map<String, dynamic> toJson() => {'is_active': isActive};
}
