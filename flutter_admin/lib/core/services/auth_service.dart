import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_core/core/network/api_client.dart';
import 'package:flutter_core/core/network/api_endpoints.dart';
import 'package:flutter_core/core/storage/token_storage.dart';
import '../storage/admin_token_storage.dart';
import 'package:flutter_core/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final _authStateController = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  final TokenStorage _tokenStorage = AdminTokenStorage();
  final ApiClient _apiClient = ApiClient();

  User? _currentUser;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  ValueNotifier<AuthStatus> get authState => _authStateController;
  User? get currentUser => _currentUser;

  Future<void> initialize() async {
    try {
      // Set up the unauthorized callback in ApiClient
      _apiClient.setUnauthorizedCallback(() {
        logout();
      });

      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        try {
          await fetchCurrentUser();
          _authStateController.value = AuthStatus.authenticated;
        } catch (e) {
          debugPrint('Error fetching user: $e');
          _authStateController.value = AuthStatus.unauthenticated;
        }
      } else {
        _authStateController.value = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('AuthService initialization failed: $e');
      _authStateController.value = AuthStatus.unauthenticated;
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('${ApiEndpoints.users}/me');
      _currentUser = User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? nickname,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (nickname != null) 'nickname': nickname,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      _currentUser = authResponse.user;
      _authStateController.value = AuthStatus.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _currentUser = null;
    _authStateController.value = AuthStatus.unauthenticated;
  }
}
