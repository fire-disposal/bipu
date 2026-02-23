import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

/// 头像 API 服务提供者
final avatarApiProvider = Provider<AvatarApiService>((ref) {
  return AvatarApiService();
});

/// 头像服务
///
/// 提供用户头像和服务号头像的获取与上传功能
///
/// API 端点：
/// - GET /api/profile/avatar/{bipupu_id} - 获取用户头像
/// - POST /api/profile/avatar - 上传用户头像
/// - GET /api/service-accounts/{name}/avatar - 获取服务号头像
class AvatarApiService {
  /// 获取用户头像 URL
  ///
  /// [bipupuId] 用户的 bipupu_id
  /// 返回头像的完整 URL 字符串
  String getUserAvatarUrl(String bipupuId) {
    return 'http://localhost:8000/api/profile/avatar/$bipupuId';
  }

  /// 获取服务号头像 URL
  ///
  /// [serviceName] 服务号名称
  /// 返回头像的完整 URL 字符串
  String getServiceAccountAvatarUrl(String serviceName) {
    return 'http://localhost:8000/api/service-accounts/$serviceName/avatar';
  }

  /// 获取用户头像数据
  ///
  /// 返回头像的字节数据，可用于缓存或本地处理
  Future<Uint8List?> getUserAvatarData(String bipupuId) async {
    try {
      final dio = await _getAuthorizedDio();
      final response = await dio.get<Uint8List>(
        getUserAvatarUrl(bipupuId),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('[AvatarApi] 用户头像不存在：$bipupuId');
      } else {
        debugPrint('[AvatarApi] 获取用户头像失败：${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('[AvatarApi] 获取用户头像异常：$e');
      return null;
    }
  }

  /// 获取服务号头像数据
  Future<Uint8List?> getServiceAccountAvatarData(String serviceName) async {
    try {
      final dio = await _getAuthorizedDio();
      final response = await dio.get<Uint8List>(
        getServiceAccountAvatarUrl(serviceName),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('[AvatarApi] 服务号头像不存在：$serviceName');
      } else {
        debugPrint('[AvatarApi] 获取服务号头像失败：${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('[AvatarApi] 获取服务号头像异常：$e');
      return null;
    }
  }

  /// 上传用户头像
  ///
  /// [avatarBytes] 头像图片的字节数据
  /// [fileName] 文件名（可选，默认使用 avatar.jpg）
  ///
  /// 返回上传成功后的用户数据（包含新的头像 URL）
  Future<Map<String, dynamic>?> uploadUserAvatar(
    Uint8List avatarBytes, {
    String fileName = 'avatar.jpg',
  }) async {
    try {
      final dio = await _getAuthorizedDio();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(avatarBytes, filename: fileName),
      });

      final response = await dio.post<Map<String, dynamic>>(
        '/api/profile/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        debugPrint('[AvatarApi] 用户头像上传成功');
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[AvatarApi] 用户头像上传失败：${e.message}');
      return null;
    } catch (e) {
      debugPrint('[AvatarApi] 用户头像上传异常：$e');
      return null;
    }
  }

  /// 获取认证头
  Future<Map<String, String>> _getAuthHeaders() async {
    // TODO: 从本地存储获取 token
    // 目前返回空 headers，后续需要集成认证模块
    return {};
  }

  /// 获取已授权的 Dio 实例
  Future<Dio> _getAuthorizedDio() async {
    // 直接使用 Dio 实例，认证头由 _getAuthHeaders 提供
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: await _getAuthHeaders(),
      ),
    );

    return dio;
  }
}

/// 头像缓存提供者
///
/// 缓存用户和服务号的头像数据，避免重复请求
final avatarCacheProvider =
    NotifierProvider<AvatarCacheNotifier, Map<String, Uint8List>>(
      AvatarCacheNotifier.new,
    );

class AvatarCacheNotifier extends Notifier<Map<String, Uint8List>> {
  @override
  Map<String, Uint8List> build() {
    return {};
  }

  /// 缓存用户头像
  void cacheUserAvatar(String bipupuId, Uint8List data) {
    state = {...state, 'user:$bipupuId': data};
  }

  /// 缓存服务号头像
  void cacheServiceAccountAvatar(String serviceName, Uint8List data) {
    state = {...state, 'service:$serviceName': data};
  }

  /// 获取缓存的用户头像
  Uint8List? getCachedUserAvatar(String bipupuId) {
    return state['user:$bipupuId'];
  }

  /// 获取缓存的服务号头像
  Uint8List? getCachedServiceAccountAvatar(String serviceName) {
    return state['service:$serviceName'];
  }

  /// 清除用户头像缓存
  void clearUserAvatarCache(String bipupuId) {
    final newState = Map<String, Uint8List>.from(state);
    newState.remove('user:$bipupuId');
    state = newState;
  }

  /// 清除服务号头像缓存
  void clearServiceAccountAvatarCache(String serviceName) {
    final newState = Map<String, Uint8List>.from(state);
    newState.remove('service:$serviceName');
    state = newState;
  }

  /// 清除所有缓存
  void clearAll() {
    state = {};
  }
}
