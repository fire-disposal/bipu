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
      logger.i('📦 ModelManager: 所有请求的模型已存在，跳过');
      return;
    }

    logger.i('🚀 ModelManager: 开始初始化模型...');
    logger.i('📋 新模型清单: ${models.length} 个文件');
    logger.i('📋 已有模型: ${_modelPaths.length} 个文件');

    // 打印所有模型文件
    models.forEach((key, value) {
      logger.i('   - $key -> $value');
    });

    try {
      // 获取应用支持目录
      logger.i('📁 获取应用支持目录...');
      final dir = await getApplicationSupportDirectory();
      logger.i('   ✅ 应用支持目录: ${dir.path}');

      // 创建模型根目录
      final modelsRoot = Directory('${dir.path}/models');
      logger.i('📁 检查模型目录: ${modelsRoot.path}');

      if (!await modelsRoot.exists()) {
        logger.i('   📁 创建模型目录...');
        await modelsRoot.create(recursive: true);
        logger.i('   ✅ 模型目录创建成功');
      } else {
        logger.i('   ✅ 模型目录已存在');
      }

      logger.i('📦 开始处理模型文件...');
      int successCount = 0;
      int skipCount = 0;
      int errorCount = 0;
      int alreadyExistCount = 0;

      for (final entry in models.entries) {
        final key = entry.key;
        final assetPath = entry.value; // e.g. assets/models/asr/encoder.onnx
        final dest = File('${modelsRoot.path}/$key');

        logger.i('\n🔍 处理模型: $key');
        logger.i('   📄 源文件: $assetPath');
        logger.i('   💾 目标文件: ${dest.path}');

        try {
          // 检查是否已经注册过这个key
          if (_modelPaths.containsKey(key)) {
            logger.i('   ✅ 模型已注册，跳过: $key');
            alreadyExistCount++;
            continue;
          }

          if (!await dest.exists()) {
            logger.i('   📤 文件不存在，开始复制...');
            await _copyAssetToFile(assetPath, dest);
            logger.i('   ✅ 文件复制成功');
            successCount++;
          } else {
            logger.i('   ⏭️  文件已存在，跳过复制');
            skipCount++;
          }

          _modelPaths[key] = dest.path;
          logger.i('   📍 路径已注册: $key -> ${dest.path}');
        } catch (e) {
          logger.e('   ❌ 处理失败: $e');
          errorCount++;
          // 继续处理其他文件，不中断整个流程
        }
      }

      logger.i('\n📊 模型处理完成:');
      logger.i('   ✅ 成功复制: $successCount 个文件');
      logger.i('   ⏭️  跳过已存在: $skipCount 个文件');
      logger.i('   ✅ 已注册: $alreadyExistCount 个文件');
      logger.i('   ❌ 失败: $errorCount 个文件');

      if (errorCount > 0) {
        logger.w('⚠️  警告: 部分模型文件处理失败，可能影响功能');
      }

      logger.i('🎉 ModelManager: 模型处理完成');
      logger.i('📁 总模型数量: ${_modelPaths.length}');

      // 打印所有已注册的模型路径
      logger.i('📋 已注册模型路径:');
      _modelPaths.forEach((key, path) {
        logger.i('   - $key: $path');
      });
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
    } else {
      logger.i('🔍 ModelManager: 获取模型路径 key="$key" -> $path');
    }
    return path;
  }

  Future<void> _copyAssetToFile(String assetPath, File dest) async {
    logger.i('   📦 开始复制文件: $assetPath');

    try {
      // 检查文件是否存在
      logger.i('   🔍 检查Asset文件是否存在...');
      final byteData = await rootBundle.load(assetPath);
      logger.i('   ✅ Asset文件加载成功，大小: ${byteData.lengthInBytes} 字节');

      final bytes = byteData.buffer.asUint8List();

      // 确保目标目录存在
      logger.i('   📁 创建目标目录...');
      await dest.create(recursive: true);
      logger.i('   ✅ 目标目录创建成功');

      // 写入文件
      logger.i('   💾 写入文件...');
      await dest.writeAsBytes(bytes, flush: true);

      // 验证文件
      final fileSize = await dest.length();
      logger.i('   ✅ 文件写入成功，大小: $fileSize 字节');

      if (fileSize == byteData.lengthInBytes) {
        logger.i('   ✅ 文件大小验证通过');
      } else {
        logger.w(
          '   ⚠️  警告: 文件大小不匹配 (预期: ${byteData.lengthInBytes}, 实际: $fileSize)',
        );
      }
    } catch (e, stackTrace) {
      logger.e('   ❌ 复制文件失败: $e');
      logger.e('   📄 堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 清理内部状态（不删除磁盘文件）
  void reset() {
    logger.i('🔄 ModelManager: 重置状态');
    logger.i('   📋 清除 ${_modelPaths.length} 个模型路径');
    _modelPaths.clear();
    logger.i('✅ ModelManager: 状态重置完成');
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
