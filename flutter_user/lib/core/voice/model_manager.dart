import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/logger.dart';

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

      logger.i(
        'Processing model: key=$key, assetPath=$assetPath, dest=${dest.path}',
      );

      if (!await dest.exists()) {
        logger.i('Copying asset $assetPath to ${dest.path}');
        try {
          await _copyAssetToFile(assetPath, dest);
          logger.i('Copied asset $assetPath successfully');

          // Verify file was copied
          if (await dest.exists()) {
            final fileSize = await dest.length();
            logger.i(
              'File verification: ${dest.path} exists, size: $fileSize bytes',
            );
          } else {
            logger.e(
              'File verification failed: ${dest.path} does not exist after copy',
            );
          }
        } catch (e, stackTrace) {
          logger.e(
            'Failed to copy asset $assetPath',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      } else {
        final fileSize = await dest.length();
        logger.i(
          'Model $key already exists at ${dest.path}, size: $fileSize bytes',
        );
      }
      _modelPaths[key] = dest.path;
      logger.i('Added to model paths: $key -> ${dest.path}');
    }

    _initialized = true;
  }

  /// 返回已准备好的本地模型路径，key 为 ensureInitialized 中使用的 key。
  String? getModelPath(String key) => _modelPaths[key];

  Future<void> _copyAssetToFile(String assetPath, File dest) async {
    try {
      logger.i('Loading asset from $assetPath');

      // Check if asset exists in bundle
      try {
        final manifest = await rootBundle.loadString('AssetManifest.json');
        logger.i('Asset manifest loaded, checking for $assetPath');
        if (!manifest.contains(assetPath)) {
          logger.w('Asset $assetPath not found in AssetManifest.json');
        }
      } catch (e) {
        logger.w('Could not load AssetManifest.json: $e');
      }

      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      logger.i('Asset loaded successfully, size: ${bytes.length} bytes');

      // Create parent directory if it doesn't exist
      final parentDir = dest.parent;
      if (!await parentDir.exists()) {
        logger.i('Creating parent directory: ${parentDir.path}');
        await parentDir.create(recursive: true);
      }

      logger.i('Writing asset to ${dest.path}');
      await dest.writeAsBytes(bytes, flush: true);

      // Verify write
      if (await dest.exists()) {
        final writtenSize = await dest.length();
        logger.i(
          'Asset written successfully to ${dest.path}, size: $writtenSize bytes',
        );
        if (writtenSize != bytes.length) {
          logger.w(
            'Size mismatch: original=${bytes.length} bytes, written=$writtenSize bytes',
          );
        }
      } else {
        logger.e('File does not exist after write: ${dest.path}');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to copy asset $assetPath to ${dest.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 清理内部状态（不删除磁盘文件）
  void reset() {
    _initialized = false;
    _modelPaths.clear();
  }
}
