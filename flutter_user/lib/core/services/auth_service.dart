import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/api/auth_api.dart';
import 'package:flutter_user/core/storage/token_storage.dart';
import '../storage/mobile_token_storage.dart';
import 'package:flutter_user/models/models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final _authStateController = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  final TokenStorage _tokenStorage = MobileTokenStorage();
  late final AuthApi _api = AuthApi();

  UserResponse? _currentUser;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  ValueNotifier<AuthStatus> get authState => _authStateController;
  UserResponse? get currentUser => _currentUser;

  Future<void> initialize() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          await fetchCurrentUser();
          _authStateController.value = AuthStatus.authenticated;
        } catch (e) {
          debugPrint('Error fetching user: $e');
          // Clear invalid token
          await _tokenStorage.clearTokens();
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
      _currentUser = await _api.getMe();
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
      await _api.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
          nickname: nickname,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final token = await _api.login(
        LoginRequest(username: username, password: password),
      );

      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      // Always fetch current user after login to ensure we have the latest user data
      await fetchCurrentUser();
      _authStateController.value = AuthStatus.authenticated;
    } catch (e) {
      // Clear any partially saved tokens on failure
      await _tokenStorage.clearTokens();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _currentUser = null;
    _authStateController.value = AuthStatus.unauthenticated;
  }
}
