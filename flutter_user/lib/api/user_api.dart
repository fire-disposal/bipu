import 'api.dart';
import '../models/user/user_response.dart';

class UserApi {
  final ApiClient _api;

  UserApi([ApiClient? client]) : _api = client ?? api;

  Future<UserResponse> getUserByBipupuId(String bipupuId) async {
    final data = await _api.get<Map<String, dynamic>>('/api/users/$bipupuId');
    return UserResponse.fromJson(data);
  }
}
