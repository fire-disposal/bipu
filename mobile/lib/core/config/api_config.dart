import 'package:flutter/foundation.dart';

/// API配置类
/// 用于管理API基础URL和配置
@immutable
class ApiConfig {
  /// API基础URL - 使用单一端点
  static const String baseUrl = 'https://api.205716.xyz';

  /// 获取海报图片URL
  static String getPosterImageUrl(int posterId) {
    return '$baseUrl/api/posters/$posterId/image';
  }

  /// 获取API超时时间（毫秒）
  static const int apiTimeout = 30000; // 30秒

  /// 获取重试次数
  static const int maxRetries = 3;

  /// 获取分页大小
  static const int defaultPageSize = 20;

  /// 获取海报轮播限制数量
  static const int posterCarouselLimit = 10;

  /// 获取长轮询超时时间（秒）
  static const int pollTimeout = 30;

  /// 获取最大长轮询超时时间（秒）
  static const int maxPollTimeout = 120;

  /// 检查是否是开发环境
  static bool get isDev => false;

  /// 检查是否是测试环境
  static bool get isTest => false;

  /// 检查是否是生产环境
  static bool get isProd => true;

  /// 获取环境名称
  static String get environment => '生产环境';

  /// 获取API版本
  static const String apiVersion = 'v1';

  /// 获取完整的API路径
  static String getApiPath(String endpoint) {
    // 移除开头的斜杠（如果有）
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    return '$baseUrl/$cleanEndpoint';
  }

  /// 获取WebSocket URL
  static String getWebSocketUrl() {
    final url = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$url/ws';
  }

  /// 获取上传文件大小限制（字节）
  static const int maxUploadSize = 10 * 1024 * 1024; // 10MB

  /// 获取支持的图片格式
  static const List<String> supportedImageFormats = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  /// 获取支持的音频格式
  static const List<String> supportedAudioFormats = [
    'audio/mpeg',
    'audio/wav',
    'audio/ogg',
    'audio/webm',
  ];

  /// 获取用户代理
  static String getUserAgent() {
    return 'Bipupu-Mobile/1.0.0 (${environment})';
  }

  /// 获取默认请求头
  static Map<String, String> getDefaultHeaders() {
    return {
      'User-Agent': getUserAgent(),
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// 获取图片请求头
  static Map<String, String> getImageHeaders() {
    return {'User-Agent': getUserAgent(), 'Accept': 'image/*'};
  }

  /// 获取音频请求头
  static Map<String, String> getAudioHeaders() {
    return {'User-Agent': getUserAgent(), 'Accept': 'audio/*'};
  }

  /// 获取文件上传请求头
  static Map<String, String> getUploadHeaders() {
    return {
      'User-Agent': getUserAgent(),
      'Content-Type': 'multipart/form-data',
    };
  }
}
