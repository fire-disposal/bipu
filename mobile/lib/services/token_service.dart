import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../models/user_model.dart';
import 'base_service.dart';

/// Token刷新状态
enum TokenRefreshStatus {
  idle, // 空闲
  refreshing, // 刷新中
  success, // 刷新成功
  failed, // 刷新失败
  expired, // 刷新令牌过期
}

/// Token服务 - 独立的Token管理服务
class TokenService extends GetxService {
  static TokenService get instance => Get.find();

  // Token状态
  final Rx<TokenRefreshStatus> refreshStatus = TokenRefreshStatus.idle.obs;
  final RxString error = ''.obs;
  final RxBool hasValidToken = false.obs;
  final RxInt tokenExpiryTime = 0.obs; // token过期时间戳（秒）

  // 防止并发刷新
  Completer<bool>? _refreshCompleter;
  Timer? _refreshTimer;

  // Dio实例（用于刷新请求）
  late Dio _refreshDio;

  @override
  void onInit() {
    super.onInit();
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 初始化时检查token状态
    _checkTokenStatus();

    // 启动定时检查token过期
    _startTokenExpiryCheck();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshCompleter?.complete(false);
    super.onClose();
  }

  /// 检查token状态
  Future<void> _checkTokenStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    hasValidToken.value = accessToken != null && accessToken.isNotEmpty;

    // 如果有access_token，计算过期时间
    if (accessToken != null) {
      _updateTokenExpiryTime(accessToken);
    }
  }

  /// 更新token过期时间
  void _updateTokenExpiryTime(String token) {
    try {
      // 解析JWT token获取过期时间
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        // Base64解码
        final decoded = String.fromCharCodes(
          base64.decode(_fixBase64Padding(payload)),
        );
        final payloadMap = Map<String, dynamic>.from(json.decode(decoded));
        final exp = payloadMap['exp'] as int?;
        if (exp != null) {
          tokenExpiryTime.value = exp;
        }
      }
    } catch (e) {
      // 解析失败，使用默认过期时间（当前时间+30分钟）
      tokenExpiryTime.value =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1800;
    }
  }

  /// 修复Base64填充
  String _fixBase64Padding(String encoded) {
    final padding = 4 - (encoded.length % 4);
    if (padding < 4) {
      return encoded + '=' * padding;
    }
    return encoded;
  }

  /// 启动token过期检查定时器
  void _startTokenExpiryCheck() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkAndRefreshIfNeeded();
    });
  }

  /// 检查并刷新token（如果需要）
  Future<bool> _checkAndRefreshIfNeeded() async {
    // 如果没有有效的token，不需要刷新
    if (!hasValidToken.value) {
      return false;
    }

    // 检查token是否即将过期（5分钟内过期）
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiry = tokenExpiryTime.value - currentTime;

    if (timeUntilExpiry <= 300) {
      // 5分钟
      return await refreshToken();
    }

    return false;
  }

  /// 刷新token
  Future<bool> refreshToken() async {
    // 如果已经在刷新中，等待结果
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    refreshStatus.value = TokenRefreshStatus.refreshing;
    error.value = '';

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        refreshStatus.value = TokenRefreshStatus.expired;
        error.value = '刷新令牌不存在';
        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        return false;
      }

      // 发送刷新请求
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/public/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokenData = Token.fromJson(response.data!);

        // 保存新的token
        await prefs.setString('access_token', tokenData.accessToken);

        // 如果返回了新的refresh_token，更新它
        if (tokenData.refreshToken != null &&
            tokenData.refreshToken!.isNotEmpty) {
          await prefs.setString('refresh_token', tokenData.refreshToken!);
        }

        // 更新token过期时间
        _updateTokenExpiryTime(tokenData.accessToken);
        hasValidToken.value = true;

        // 通知所有监听者token已刷新
        Get.find<BaseService>().updateToken(tokenData.accessToken);

        refreshStatus.value = TokenRefreshStatus.success;
        error.value = '';

        _refreshCompleter?.complete(true);
        _refreshCompleter = null;
        return true;
      } else {
        refreshStatus.value = TokenRefreshStatus.failed;
        error.value = '刷新令牌失败: ${response.statusCode}';

        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        return false;
      }
    } on DioException catch (e) {
      refreshStatus.value = TokenRefreshStatus.failed;

      if (e.response?.statusCode == 401) {
        error.value = '刷新令牌已过期，请重新登录';
        refreshStatus.value = TokenRefreshStatus.expired;

        // 清除无效的token
        await clearTokens();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        error.value = '网络连接超时';
      } else if (e.type == DioExceptionType.connectionError) {
        error.value = '网络连接错误';
      } else {
        error.value = '刷新令牌失败: ${e.message}';
      }

      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      return false;
    } catch (e) {
      refreshStatus.value = TokenRefreshStatus.failed;
      error.value = '刷新令牌失败: $e';

      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      return false;
    }
  }

  /// 强制刷新token（忽略并发控制）
  Future<bool> forceRefreshToken() async {
    _refreshCompleter?.complete(false);
    _refreshCompleter = null;
    return await refreshToken();
  }

  /// 获取当前access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// 获取当前refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  /// 保存token
  Future<void> saveTokens(Token token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token.accessToken);

    if (token.refreshToken != null && token.refreshToken!.isNotEmpty) {
      await prefs.setString('refresh_token', token.refreshToken!);
    }

    _updateTokenExpiryTime(token.accessToken);
    hasValidToken.value = true;
  }

  /// 清除所有token
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    hasValidToken.value = false;
    tokenExpiryTime.value = 0;
    refreshStatus.value = TokenRefreshStatus.idle;
    error.value = '';
  }

  /// 检查token是否有效
  Future<bool> isTokenValid() async {
    if (!hasValidToken.value) {
      return false;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiry = tokenExpiryTime.value - currentTime;

    // 如果token还有至少1分钟的有效期，认为是有效的
    return timeUntilExpiry > 60;
  }

  /// 检查token是否即将过期（5分钟内）
  Future<bool> isTokenAboutToExpire() async {
    if (!hasValidToken.value) {
      return false;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiry = tokenExpiryTime.value - currentTime;

    return timeUntilExpiry <= 300; // 5分钟
  }

  /// 获取token剩余有效期（秒）
  Future<int> getTokenRemainingTime() async {
    if (!hasValidToken.value) {
      return 0;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiry = tokenExpiryTime.value - currentTime;

    return timeUntilExpiry > 0 ? timeUntilExpiry : 0;
  }

  /// 重置刷新状态
  void resetRefreshStatus() {
    refreshStatus.value = TokenRefreshStatus.idle;
    error.value = '';
  }
}
