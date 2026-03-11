import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// 虚拟接线员人格模型
class OperatorPersonality extends Equatable {
  /// 接线员唯一 ID
  final String id;

  /// 接线员名称
  final String name;

  /// 接线员描述
  final String description;

  /// 立绘资源 URL 或 Asset 路径
  final String portraitUrl;

  /// 首字母头像（用于未解锁状态）
  final String initials;

  /// TTS 语音 ID（用于语音播报，范围 1-178）
  final int ttsId;

  /// TTS 语速 (0.5-2.0)
  final double ttsSpeed;

  /// 接线员主题色
  final Color themeColor;

  /// 接线员台词配置
  final OperatorDialogues dialogues;

  /// 是否已解锁
  final bool isUnlocked;

  /// 解锁时间戳
  final DateTime? unlockedAt;

  /// 完成对话次数
  final int conversationCount;

  const OperatorPersonality({
    required this.id,
    required this.name,
    required this.description,
    required this.portraitUrl,
    required this.initials,
    required this.ttsId,
    this.ttsSpeed = 1.0,
    required this.themeColor,
    required this.dialogues,
    this.isUnlocked = false,
    this.unlockedAt,
    this.conversationCount = 0,
  });

  /// 复制并修改
  OperatorPersonality copyWith({
    String? id,
    String? name,
    String? description,
    String? portraitUrl,
    String? initials,
    int? ttsId,
    double? ttsSpeed,
    Color? themeColor,
    OperatorDialogues? dialogues,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? conversationCount,
  }) {
    return OperatorPersonality(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      initials: initials ?? this.initials,
      ttsId: ttsId ?? this.ttsId,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      themeColor: themeColor ?? this.themeColor,
      dialogues: dialogues ?? this.dialogues,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      conversationCount: conversationCount ?? this.conversationCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    portraitUrl,
    initials,
    ttsId,
    ttsSpeed,
    themeColor,
    dialogues,
    isUnlocked,
    unlockedAt,
    conversationCount,
  ];
}

/// 接线员台词配置
class OperatorDialogues extends Equatable {
  /// 初始问候语（多个变体，随机选择）
  final List<String> greetingVariants;

  /// 确认 ID 的台词（多个变体）
  final List<String> confirmIdVariants;

  /// 核实信息的台词（多个变体）
  final List<String> verifyVariants;

  /// 请求消息的台词（多个变体）
  final List<String> requestMessageVariants;

  /// 检测到表情符号时的提醒（多个变体）
  final List<String> emojiWarningVariants;

  /// 消息发送成功的台词（多个变体）
  final List<String> successMessageVariants;

  /// 用户不存在时的提示（多个变体）
  final List<String> userNotFoundVariants;

  /// 其他随机台词
  final List<String> randomPhrases;

  /// 接通后询问目标用户 ID 的台词（多个变体）
  final List<String> askTargetVariants;

  /// 发送成功后询问是否继续的台词（多个变体）
  final List<String> askContinueVariants;

  const OperatorDialogues({
    required this.greetingVariants,
    required this.confirmIdVariants,
    required this.requestMessageVariants,
    required this.successMessageVariants,
    required this.userNotFoundVariants,
    this.verifyVariants = const [],
    this.emojiWarningVariants = const [],
    this.randomPhrases = const [],
    this.askTargetVariants = const ['请告诉我您要联系的用户 ID'],
    this.askContinueVariants = const ['是否需要继续发送给其他用户？'],
  });

  @override
  List<Object?> get props => [
    greetingVariants,
    confirmIdVariants,
    verifyVariants,
    requestMessageVariants,
    emojiWarningVariants,
    successMessageVariants,
    userNotFoundVariants,
    randomPhrases,
    askTargetVariants,
    askContinueVariants,
  ];
}

/// 接线员配置加载器
class OperatorConfigLoader {
  static const String _configPath = 'assets/config/operators.yaml';
  static List<OperatorPersonality>? _cachedOperators;
  static final _loadLock = Completer<void>();

  /// 从 YAML 文件加载所有接线员配置
  static Future<List<OperatorPersonality>> loadOperators() async {
    if (_cachedOperators != null) {
      log('[OperatorConfigLoader] 返回缓存的接线员配置，数量: ${_cachedOperators!.length}');
      return _cachedOperators!;
    }

    if (_loadLock.isCompleted) {
      await _loadLock.future;
      log('[OperatorConfigLoader] 等待加载完成，数量: ${_cachedOperators!.length}');
      return _cachedOperators!;
    }

    try {
      log('[OperatorConfigLoader] 开始加载 YAML: $_configPath');
      final yamlString = await rootBundle.loadString(_configPath);
      final yaml = loadYaml(yamlString) as YamlMap;
      final operatorsList = yaml['operators'] as YamlList;

      log('[OperatorConfigLoader] YAML 解析成功，原始数据条目数: ${operatorsList.length}');

      _cachedOperators = operatorsList
          .map((op) => _parseOperator(op as YamlMap))
          .toList();

      // 输出所有加载的接线员信息
      log('[OperatorConfigLoader] ===== 接线员配置加载完成 =====');
      log('[OperatorConfigLoader] 总计: ${_cachedOperators!.length} 位接线员');
      for (var i = 0; i < _cachedOperators!.length; i++) {
        final op = _cachedOperators![i];
        log('[OperatorConfigLoader] [$i] ${op.id}: ${op.name} (颜色: ${op.themeColor})');
      }
      log('[OperatorConfigLoader] ===============================');

      _loadLock.complete();
      return _cachedOperators!;
    } catch (e, stackTrace) {
      log('[OperatorConfigLoader] 加载失败: $e');
      log('[OperatorConfigLoader] 堆栈: $stackTrace');
      _loadLock.completeError(e);
      rethrow;
    }
  }

  /// 解析单个接线员配置
  static OperatorPersonality _parseOperator(YamlMap op) {
    final dialogues = op['dialogues'] as YamlMap;

    return OperatorPersonality(
      id: op['id'] as String,
      name: op['name'] as String,
      description: op['description'] as String,
      portraitUrl: op['portrait_url'] as String,
      initials: op['initials'] as String,
      ttsId: op['tts_id'] as int,
      ttsSpeed: (op['tts_speed'] as num).toDouble(),
      themeColor: _parseColor(op['theme_color'] as String),
      dialogues: OperatorDialogues(
        greetingVariants: _toList(dialogues['greeting_variants']),
        confirmIdVariants: _toList(dialogues['confirm_id_variants']),
        verifyVariants: _toList(dialogues['verify_variants']),
        requestMessageVariants: _toList(dialogues['request_message_variants']),
        emojiWarningVariants: _toList(dialogues['emoji_warning_variants']),
        successMessageVariants: _toList(dialogues['success_message_variants']),
        userNotFoundVariants: _toList(dialogues['user_not_found_variants']),
        randomPhrases: _toList(dialogues['random_phrases']),
        askTargetVariants: _toList(dialogues['ask_target_variants']),
        askContinueVariants: _toList(dialogues['ask_continue_variants']),
      ),
    );
  }

  /// 解析十六进制颜色字符串
  static Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    final value = int.parse(hex, radix: 16);
    return Color(value | 0xFF000000);
  }

  /// 将 YamlList 转换为 List<String>
  static List<String> _toList(dynamic yamlList) {
    if (yamlList == null) return [];
    return (yamlList as YamlList).map((e) => e as String).toList();
  }

  /// 清除缓存，强制重新加载
  static void clearCache() {
    _cachedOperators = null;
  }
}

/// 接线员工厂（使用加载的配置）
class OperatorFactory {
  static final _rnd = Random();
  static List<OperatorPersonality> _operators = [];
  static bool _initialized = false;

  /// 初始化加载接线员配置
  static Future<void> initialize() async {
    if (!_initialized) {
      _operators = await OperatorConfigLoader.loadOperators();
      _initialized = true;
    }
  }

  /// 确保已初始化
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 获取所有接线员
  static Future<List<OperatorPersonality>> getAllOperators() async {
    await _ensureInitialized();
    return _operators;
  }

  /// 获取随机操作员
  static Future<OperatorPersonality> getRandomOperator() async {
    await _ensureInitialized();
    return _operators[_rnd.nextInt(_operators.length)];
  }

  /// 根据 ID 获取操作员
  static Future<OperatorPersonality?> getOperatorById(String id) async {
    await _ensureInitialized();
    return _operators.firstWhereOrNull((op) => op.id == id);
  }
}
