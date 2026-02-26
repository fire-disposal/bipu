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
    final accessToken = json['access_token'] ?? json['accessToken'];
    if (accessToken == null || accessToken is! String) {
      throw FormatException('Invalid or missing access_token in response');
    }

    final expiresInValue = json['expires_in'] ?? json['expiresIn'];
    int expiresIn;
    if (expiresInValue is int) {
      expiresIn = expiresInValue;
    } else if (expiresInValue is String) {
      expiresIn = int.tryParse(expiresInValue) ?? 1800; // Default to 30 minutes
    } else {
      expiresIn = 1800; // Default to 30 minutes if null or invalid
    }

    return Token(
      accessToken: accessToken,
      refreshToken: (json['refresh_token'] ?? json['refreshToken']) is String
          ? json['refresh_token'] ?? json['refreshToken'] as String
          : null,
      tokenType: json['token_type'] ?? json['tokenType'] ?? 'bearer',
      expiresIn: expiresIn,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
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
