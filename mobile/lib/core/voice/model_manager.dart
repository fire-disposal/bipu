import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 单例：负责把打包进 assets 的模型/资源拷贝到可读写的本地目录，
/// 并提供模型路径查询接口。调用方负责传入要保证存在的模型清单。
class ModelManager {
  ModelManager._internal();
  static final ModelManager _instance = ModelManager._internal();
  static ModelManager get instance => _instance;

  bool _initialized = false;
  final Map<String, String> _modelPaths = {};

  /// 确保给定 models map 中列出的资源被拷贝到本地并准备好使用。
  ///
  /// models: key -> asset relative path (例如 'asr/encoder.onnx')
  Future<void> ensureInitialized(Map<String, String> models) async {
    if (_initialized) return;

    final dir = await getApplicationSupportDirectory();
    final modelsRoot = Directory('${dir.path}/models');
    if (!await modelsRoot.exists()) await modelsRoot.create(recursive: true);

    for (final entry in models.entries) {
      final key = entry.key;
      final assetPath = entry.value; // e.g. assets/models/asr/encoder.onnx
      final dest = File('${modelsRoot.path}/$key');
      if (!await dest.exists()) {
        await _copyAssetToFile(assetPath, dest);
      }
      _modelPaths[key] = dest.path;
    }

    _initialized = true;
  }

  /// 返回已准备好的本地模型路径，key 为 ensureInitialized 中使用的 key。
  String? getModelPath(String key) => _modelPaths[key];

  Future<void> _copyAssetToFile(String assetPath, File dest) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    await dest.create(recursive: true);
    await dest.writeAsBytes(bytes, flush: true);
  }

  /// 清理内部状态（不删除磁盘文件）
  void reset() {
    _initialized = false;
    _modelPaths.clear();
  }
}
