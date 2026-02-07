import 'package:dio/dio.dart';

import '../../models/friendship_model.dart';
import '../../models/message_model.dart';
import '../../models/message_ack_event.dart';
import '../../models/paginated_response.dart';
import '../../models/user_model.dart';
import '../../models/subscription_model.dart';
import '../../models/user_settings_model.dart';

// Temporarily remove retrofit annotations to fix compilation
class RestClient {
  RestClient(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  // Placeholder methods - implement as needed
  Future<AuthResponse> login(Map<String, dynamic> body) async {
    throw UnimplementedError();
  }

  Future<User> register(Map<String, dynamic> body) async {
    throw UnimplementedError();
  }

  Future<AuthResponse> refreshToken(Map<String, dynamic> body) async {
    throw UnimplementedError();
  }

  Future<void> logout() async {
    throw UnimplementedError();
  }

  Future<User> getMe() async {
    throw UnimplementedError();
  }

  Future<User> updateMe(Map<String, dynamic> body) async {
    throw UnimplementedError();
  }

  Future<User> updateAvatar(MultipartFile file) async {
    throw UnimplementedError();
  }

  Future<void> updateOnlineStatus(Map<String, dynamic> body) async {
    throw UnimplementedError();
  }

  // Add other methods as needed...
}
