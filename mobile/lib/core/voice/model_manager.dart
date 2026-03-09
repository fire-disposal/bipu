import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// 单例：负责把打包进 assets 的模型/资源拷贝到可读写的本地目录，
/// 并提供模型路径查询接口。调用方负责传入要保证存在的模型清单。
class ModelManager {
  ModelManager._internal();
  static final ModelManager _instance = ModelManager._internal();
  static ModelManager get instance => _instance;

  final Map<String, String> _modelPaths = {};

  /// 确保给定 models map 中列出的资源被拷贝到本地并准备好使用。
  ///
  /// models: key -> asset relative path (例如 'asr/encoder.onnx')
  Future<void> ensureInitialized(Map<String, String> models) async {
    // 检查是否已经初始化过这些模型
    bool allModelsExist = true;
    for (final key in models.keys) {
      if (!_modelPaths.containsKey(key)) {
        allModelsExist = false;
        break;
      }
    }

    if (allModelsExist && _modelPaths.isNotEmpty) {
      return;
    }

    try {
      final dir = await getApplicationSupportDirectory();

      // 创建模型根目录
      final modelsRoot = Directory('${dir.path}/models');
      if (!await modelsRoot.exists()) {
        await modelsRoot.create(recursive: true);
      }

      // 并行处理所有模型文件（显著降低多文件地首次复制时的耳尘时间）
      final results = await Future.wait(
        models.entries.map((entry) async {
          final key = entry.key;
          final assetPath = entry.value;
          final dest = File('${modelsRoot.path}/$key');

          if (_modelPaths.containsKey(key)) {
            return true;
          }

          try {
            if (!await dest.exists()) {
              logger.i('📤 ModelManager: 复制模型 $key');
              await _copyAssetToFile(assetPath, dest);
            }
            _modelPaths[key] = dest.path;
            return true;
          } catch (e) {
            logger.e('   ❌ 处理失败: $key -> $e');
            return false;
          }
        }),
      );

      final errorCount = results.where((ok) => !ok).length;
      if (errorCount > 0) {
        logger.w('⚠️  警告: $errorCount 个模型文件处理失败，可能影响功能');
      }

      logger.i('✅ ModelManager: ${_modelPaths.length} 个模型就绪');
    } catch (e, stackTrace) {
      logger.e('❌ ModelManager: 初始化失败');
      logger.e('   🔴 错误: $e');
      logger.e('   📄 堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 返回已准备好的本地模型路径，key 为 ensureInitialized 中使用的 key。
  String? getModelPath(String key) {
    final path = _modelPaths[key];
    if (path == null) {
      logger.w('⚠️  ModelManager: 未找到模型路径 key="$key"');
      logger.w('   📋 可用keys: ${_modelPaths.keys.toList()}');
    }
    return path;
  }

  Future<void> _copyAssetToFile(String assetPath, File dest) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      await dest.create(recursive: true);
      await dest.writeAsBytes(bytes, flush: true);
      final fileSize = await dest.length();
      if (fileSize != byteData.lengthInBytes) {
        logger.w(
          '⚠️  ModelManager: 文件大小不匹配 $assetPath (预期: ${byteData.lengthInBytes}, 实际: $fileSize)',
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        '❌ ModelManager: 复制文件失败 $assetPath',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 清理内部状态（不删除磁盘文件）
  void reset() {
    logger.i('🔄 ModelManager: 重置 (${_modelPaths.length} 个路径)');
    _modelPaths.clear();
  }

  /// 清理无效或错误的模型文件
  Future<void> cleanupInvalidFiles(Map<String, String> expectedModels) async {
    logger.i('🧹 ModelManager: 开始清理无效文件...');
    logger.i('📋 期望的模型文件: ${expectedModels.length} 个');

    try {
      final dir = await getApplicationSupportDirectory();
      final modelsRoot = Directory('${dir.path}/models');

      if (!await modelsRoot.exists()) {
        logger.i('✅ 模型目录不存在，无需清理');
        return;
      }

      // 获取所有已存在的文件
      final existingFiles = <String>[];
      final listStream = modelsRoot.list();
      await for (final entity in listStream) {
        if (entity is File) {
          existingFiles.add(entity.path);
        }
      }

      // 检查并清理不在期望列表中的文件
      int cleanedCount = 0;
      for (final filePath in existingFiles) {
        final relativePath = filePath.replaceFirst('${modelsRoot.path}/', '');

        // 检查文件是否在期望的模型中
        bool isExpected = expectedModels.containsKey(relativePath);

        if (!isExpected) {
          logger.i('🗑️  清理无效文件: $relativePath');
          try {
            await File(filePath).delete();
            cleanedCount++;
          } catch (e) {
            logger.w('⚠️  无法删除文件 $relativePath: $e');
          }
        }
      }

      logger.i('✅ 清理完成，删除了 $cleanedCount 个无效文件');
    } catch (e, stackTrace) {
      logger.e('❌ 清理无效文件时出错: $e');
      logger.e('   📄 堆栈: $stackTrace');
    }
  }

  /// 获取当前状态信息
  Map<String, dynamic> getStatus() {
    return {'modelCount': _modelPaths.length, 'models': Map.from(_modelPaths)};
  }

  /// 打印状态信息
  void printStatus() {
    logger.i('📊 ModelManager 状态:');
    logger.i('   📦 模型数量: ${_modelPaths.length}');
    logger.i('   📋 模型列表:');
    _modelPaths.forEach((key, path) {
      logger.i('     - $key: $path');
    });
  }
}
