import 'package:dio/dio.dart';
import '../models/user/user_response.dart';

class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  Future<UserResponse> getUserByBipupuId(String bipupuId) async {
    final response = await _dio.get('/api/users/$bipupuId');
    return UserResponse.fromJson(response.data);
  }
}
