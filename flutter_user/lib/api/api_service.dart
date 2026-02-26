import 'package:dio/dio.dart';
import 'package:flutter_user/models/auth/token.dart';
import 'package:flutter_user/models/user/user_response.dart';
import 'package:flutter_user/models/message/message_response.dart';
import 'package:flutter_user/models/contact/contact.dart';
import 'package:flutter_user/models/service/service_account.dart';
import 'package:flutter_user/models/service/subscription_settings.dart';
import 'package:flutter_user/models/block/blocked_user_response.dart';
import 'package:flutter_user/models/poster/poster_response.dart';
import 'package:flutter_user/models/common/paginated_response.dart';
import 'auth_api.dart';
import 'message_api.dart';
import 'contact_api.dart';
import 'service_account_api.dart';
import 'user_api.dart';
import 'block_api.dart';
import 'poster_api.dart';

// Unified API Service
class ApiService {
  final Dio _dio;
  // ignore: unused_field
  final String baseUrl;

  // API instances
  late final AuthApi auth;
  late final MessageApi messages;
  late final ContactApi contacts;
  late final ServiceAccountApi serviceAccounts;
  late final UserApi users;
  late final BlockApi blocks;
  late final PosterApi posters;

  ApiService(this._dio, {required this.baseUrl}) {
    // Initialize all API instances
    auth = AuthApi(_dio);
    messages = MessageApi(_dio);
    contacts = ContactApi(_dio);
    serviceAccounts = ServiceAccountApi(_dio);
    users = UserApi(_dio);
    blocks = BlockApi(_dio);
    posters = PosterApi(_dio);
  }

  // Helper method for pagination
  Future<PaginatedResponse<T>> fetchPaginated<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    final data = response.data as Map<String, dynamic>;

    final items = (data['items'] as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['page_size'] as int,
    );
  }

  // System health checks
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> readinessCheck() async {
    final response = await _dio.get('/ready');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> livenessCheck() async {
    final response = await _dio.get('/live');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getApiInfo() async {
    final response = await _dio.get('/');
    return response.data as Map<String, dynamic>;
  }

  // Count endpoints
  Future<Map<String, dynamic>> getCount() async {
    final response = await _dio.get('/api/count');
    return response.data as Map<String, dynamic>;
  }

  // Search endpoint
  Future<List<dynamic>> search({required String query, int limit = 20}) async {
    final response = await _dio.get(
      '/api/search',
      queryParameters: {'q': query, 'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  // Check endpoint
  Future<Map<String, dynamic>> checkBipupuId(String bipupuId) async {
    final response = await _dio.get('/api/check/$bipupuId');
    return response.data as Map<String, dynamic>;
  }

  // Convenience methods for common operations
  Future<UserResponse> getCurrentUser() async {
    return auth.getMe();
  }

  Future<Token> login(String username, String password) async {
    return auth.login({'username': username, 'password': password});
  }

  Future<Token> register(
    String username,
    String password, {
    String? nickname,
  }) async {
    return auth.register({
      'username': username,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });
  }

  Future<void> logout() async {
    await auth.logout();
  }

  Future<PaginatedResponse<MessageResponse>> getMessages({
    int page = 1,
    int size = 20,
  }) async {
    return messages.getMessages(page: page, size: size);
  }

  Future<MessageResponse> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    return messages.sendMessageSimple(
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      pattern: pattern,
      waveform: waveform,
    );
  }

  Future<PaginatedResponse<Contact>> getContacts({
    int page = 1,
    int size = 20,
  }) async {
    return contacts.getContacts(page: page, size: size);
  }

  Future<Contact> addContact(String contactId, {String? alias}) async {
    return contacts.addContactSimple(contactId, alias: alias);
  }

  Future<PaginatedResponse<ServiceAccount>> getServices({
    int page = 1,
    int size = 20,
  }) async {
    return serviceAccounts.getServices(page: page, size: size);
  }

  Future<List<SubscriptionSettings>> getUserSubscriptions() async {
    return serviceAccounts.getUserSubscriptions();
  }

  Future<PaginatedResponse<BlockedUserResponse>> getBlockedUsers({
    int page = 1,
    int size = 20,
  }) async {
    return blocks.getBlockedUsers(page: page, size: size);
  }

  Future<BlockedUserResponse> blockUser(String bipupuId) async {
    return blocks.blockUserByBipupuId(bipupuId);
  }

  Future<void> unblockUser(String bipupuId) async {
    await blocks.unblockUser(bipupuId);
  }

  Future<PaginatedResponse<PosterResponse>> getPosters({
    int page = 1,
    int size = 20,
  }) async {
    return posters.getPosters(page: page, size: size);
  }

  Future<List<PosterResponse>> getActivePosters({int limit = 10}) async {
    return posters.getActivePosters(limit: limit);
  }
}
