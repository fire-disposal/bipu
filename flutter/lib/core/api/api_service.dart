import 'package:openapi/openapi.dart';
import 'package:dio/dio.dart';
import '../utils/jwt_manager.dart';
import '../utils/logger.dart';

/// API服务类
/// 封装OpenAPI客户端，提供便捷的API访问和JWT认证支持
class CoreApi {
  static late final Openapi _staticClient;

  static void init({Dio? dio, String? baseUrl}) {
    // 使用传入的dio实例或创建新的，使用传入的baseUrl或默认地址
    _staticClient = Openapi(
      dio: dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? 'http://localhost:8000')),
    );
  }

  // 实例方法，用于依赖注入
  final Openapi openapi;
  final JwtManager? jwtManager;

  CoreApi({Openapi? openapi, this.jwtManager})
    : openapi = openapi ?? _staticClient;

  /// 初始化JWT认证
  Future<void> initializeAuth() async {
    if (jwtManager == null) {
      Logger.warning('JWT管理器未提供，跳过认证初始化');
      return;
    }

    final token = jwtManager!.getCurrentToken();
    if (token != null && !token.isExpired) {
      // 设置API客户端的认证信息
      openapi.setBearerAuth('HTTPBearer', token.accessToken);
      Logger.info('API认证已初始化');
    } else if (token != null && token.isExpired) {
      Logger.warning('JWT令牌已过期，需要重新登录');
      await jwtManager!.clearToken();
    }
  }

  /// 更新JWT令牌
  Future<void> updateJwtToken(String accessToken) async {
    openapi.setBearerAuth('HTTPBearer', accessToken);
    Logger.info('JWT令牌已更新');
  }

  /// 清除认证信息
  void clearAuth() {
    openapi.setBearerAuth('HTTPBearer', '');
    Logger.info('API认证信息已清除');
  }

  /// 直接访问OpenAPI实例，使用自动生成的客户端
  /// 例如：coreApi.getOpenapi().devicesApi.getDevicesApiDevicesGet()
  Openapi getOpenapi() => openapi;
}
