import 'package:dio/dio.dart';

class BlockApi {
  final Dio _dio;

  BlockApi(this._dio);

  Future<void> blockUser(int userId) async {
    await _dio.post('/api/blocks/', data: {'user_id': userId});
  }

  Future<void> unblockUser(int userId) async {
    await _dio.delete('/api/blocks/$userId');
  }
}
