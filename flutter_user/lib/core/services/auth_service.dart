import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/core/network/api_client.dart';
import 'package:flutter_user/core/network/rest_client.dart';
import 'package:flutter_user/core/storage/token_storage.dart';
import '../storage/mobile_token_storage.dart';
import 'package:flutter_user/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, guest }

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final _authStateController = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  final TokenStorage _tokenStorage = MobileTokenStorage();
  RestClient get _api => bipupuApi;

  User? _currentUser;
  bool _isGuest = false;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  ValueNotifier<AuthStatus> get authState => _authStateController;
  User? get currentUser => _currentUser;
  bool get isGuest => _isGuest;

  Future<void> initialize() async {
    try {
      // Set up the unauthorized callback in ApiClient if needed
      // ApiClient(). setUnauthorizedCallback ... (this is usually global)
      ApiClient().setUnauthorizedCallback(() {
        if (!_isGuest) logout();
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
      await _api.register({
        'username': username,
        'email': email,
        'password': password,
        if (nickname != null) 'nickname': nickname,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final authResponse = await _api.login({
        'username': username,
        'password': password,
      });

      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Backend login might not return the full User object depending on schema.
      // If AuthResponse.user is null, fetch the profile explicitly.
      _currentUser = authResponse.user;
      if (_currentUser == null) {
        await fetchCurrentUser();
      }
      _authStateController.value = AuthStatus.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginAsGuest() async {
    _isGuest = true;
    _currentUser = User(
      id: 0,
      username: 'Guest',
      email: 'guest@local',
      isActive: true,
      isSuperuser: false,
    );
    _authStateController.value = AuthStatus.guest;
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _currentUser = null;
    _isGuest = false;
    _authStateController.value = AuthStatus.unauthenticated;
  }
}
