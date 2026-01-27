import 'package:flutter/foundation.dart';
import 'package:flutter_core/core/storage/token_storage.dart';
import 'admin_token_storage.dart';
import 'web_token_storage.dart';

/// 工厂类，根据平台创建合适的 TokenStorage 实例
class TokenStorageFactory {
  static TokenStorage create() {
    if (kIsWeb) {
      return WebTokenStorage();
    } else {
      return AdminTokenStorage();
    }
  }
}
