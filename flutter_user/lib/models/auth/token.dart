import '../user/user_response.dart';

class Token {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserResponse? user;

  Token({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    required this.expiresIn,
    this.user,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      accessToken: json['access_token'] ?? json['accessToken'] as String,
      refreshToken: json['refresh_token'] ?? json['refreshToken'] as String?,
      tokenType: json['token_type'] ?? json['tokenType'] ?? 'bearer',
      expiresIn: (json['expires_in'] ?? json['expiresIn']) is int
          ? (json['expires_in'] ?? json['expiresIn']) as int
          : int.parse('${json['expires_in'] ?? json['expiresIn']}'),
      user: json['user'] != null
          ? UserResponse.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
    'user': user?.toJson(),
  };
}
