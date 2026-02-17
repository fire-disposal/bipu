import 'api.dart';

class BlockApi {
  final ApiClient _api;

  BlockApi([ApiClient? client]) : _api = client ?? api;

  Future<void> blockUser(int userId) async {
    await _api.post<void>('/api/blocks/', data: {'user_id': userId});
  }

  Future<void> unblockUser(int userId) async {
    await _api.delete<void>('/api/blocks/$userId');
  }
}
