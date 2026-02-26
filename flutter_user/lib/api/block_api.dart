import 'package:dio/dio.dart';
import '../models/block/blocked_user_response.dart';
import '../models/common/paginated_response.dart';
import '../models/block/block_user_request.dart';

class BlockApi {
  final Dio _dio;

  BlockApi(this._dio);

  Future<PaginatedResponse<BlockedUserResponse>> getBlockedUsers({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/blocks/',
      queryParameters: {'page': page, 'page_size': size},
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => BlockedUserResponse.fromJson(e))
        .toList();

    return PaginatedResponse<BlockedUserResponse>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['size'] as int,
    );
  }

  Future<BlockedUserResponse> blockUser(BlockUserRequest body) async {
    final response = await _dio.post('/api/blocks/', data: body.toJson());
    return BlockedUserResponse.fromJson(response.data);
  }

  Future<BlockedUserResponse> blockUserByBipupuId(String bipupuId) async {
    final body = BlockUserRequest(bipupuId: bipupuId);
    return blockUser(body);
  }

  Future<void> unblockUser(String bipupuId) async {
    await _dio.delete('/api/blocks/$bipupuId');
  }

  Future<bool> checkBlockStatus(String bipupuId) async {
    try {
      final response = await _dio.get('/api/blocks/check/$bipupuId');
      final data = response.data as Map<String, dynamic>;
      return data['blocked'] == true;
    } catch (_) {
      return false;
    }
  }
}
