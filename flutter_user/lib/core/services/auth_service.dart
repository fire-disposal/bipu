import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/core/storage/token_storage.dart';
import '../storage/mobile_token_storage.dart';
import 'package:flutter_user/models/models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, guest }

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final _authStateController = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  final TokenStorage _tokenStorage = MobileTokenStorage();
  ApiService get _api => bipupuApi;

  UserResponse? _currentUser;
  bool _isGuest = false;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  ValueNotifier<AuthStatus> get authState => _authStateController;
  UserResponse? get currentUser => _currentUser;
  bool get isGuest => _isGuest;

  Future<void> initialize() async {
    try {
      // Set up the unauthorized callback in ApiClient if needed
      // ApiClient().setUnauthorizedCallback(() {
      //   if (!_isGuest) logout();
      // });

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
      final token = await _api.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
          nickname: nickname,
        ),
      );
      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      if (token.user != null) {
        _currentUser = token.user;
      }
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

      if (token.user != null) {
        _currentUser = token.user;
      } else {
        await fetchCurrentUser();
      }
      _authStateController.value = AuthStatus.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginAsGuest() async {
    _isGuest = true;
    // TODO: Create a guest user response or handle differently
    _authStateController.value = AuthStatus.guest;
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _currentUser = null;
    _isGuest = false;
    _authStateController.value = AuthStatus.unauthenticated;
  }
}
