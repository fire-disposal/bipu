import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_core/core/network/api_client.dart';
import 'package:flutter_core/core/storage/token_storage.dart';
import 'package:flutter_core/repositories/user_repository.dart';
import '../storage/mobile_token_storage.dart';
import 'package:flutter_core/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, guest }

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final _authStateController = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  final TokenStorage _tokenStorage = MobileTokenStorage();
  final UserRepository _userRepository = UserRepository();

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
      _currentUser = await _userRepository.getMe();
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
      await _userRepository.register({
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
      final authResponse = await _userRepository.login(username, password);

      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Backend login might not return the full User object if the model differs,
      // but UserRepository.login returns AuthResponse which usually contains User.
      // If AuthResponse.user is optional or null, we might need to fetch it.
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

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user']),
    );
  }
}
