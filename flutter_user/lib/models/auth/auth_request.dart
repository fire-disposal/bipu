class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class RegisterRequest {
  final String email;
  final String username;
  final String password;
  final String? nickname;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    this.nickname,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'password': password,
    'nickname': nickname,
  };
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) {
    return RefreshTokenRequest(refreshToken: json['refresh_token'] as String);
  }

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
