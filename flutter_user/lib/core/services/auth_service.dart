import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_user/api/api.dart';
import 'package:flutter_user/core/storage/token_storage.dart';
import '../storage/mobile_token_storage.dart';
import '../network/api_client.dart';
import 'package:flutter_user/models/models.dart';
import '../utils/logger.dart';

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
      // 初始化API客户端
      ApiClient().init(
        baseUrl: 'https://api.205716.xyz/api',
        connectTimeout: 15000,
        receiveTimeout: 15000,
      );

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
    logger.i('Attempting to login user: $username');
    try {
      final token = await _api.login(
        LoginRequest(username: username, password: password),
      );
      logger.i('Login successful, saving tokens');

      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      if (token.user != null) {
        _currentUser = token.user;
        logger.i('User data set from token response');
      } else {
        logger.i('No user data in token response, fetching current user');
        await fetchCurrentUser();
      }
      _authStateController.value = AuthStatus.authenticated;
      logger.i('Login process completed successfully');
    } catch (e) {
      logger.e('Login failed for user: $username', error: e);
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
