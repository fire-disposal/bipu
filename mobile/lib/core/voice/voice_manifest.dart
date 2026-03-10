import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'voice_config.dart' show kUsePrerecordedVoiceOnly, kCheckVoiceResources;

/// 语音资源清单
///
/// 用于检查和管理预录制语音资源的可用性
class VoiceManifest {
  static VoiceManifest? _instance;
  static VoiceManifest get instance {
    _instance ??= VoiceManifest._();
    return _instance!;
  }

  VoiceManifest._();

  Map<String, String> _byText = {};
  Map<String, List<String>> _byOperator = {};
  bool _loaded = false;
  bool _available = false;

  /// 是否已加载
  bool get isLoaded => _loaded;

  /// 预录制语音是否可用
  bool get isAvailable => _available;

  /// 收录的台词总数
  int get totalCount => _byText.length;

  /// 按接线员 ID 分组统计
  Map<String, int> get countByOperator =>
      _byOperator.map((k, v) => MapEntry(k, v.length));

  /// 加载 manifest.json
  Future<bool> load({String basePath = 'assets/voices'}) async {
    if (_loaded) return _available;

    try {
      final raw = await rootBundle.loadString('$basePath/manifest.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;

      _byText = Map<String, String>.from(
        (data['by_text'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
      );

      // 按接线员分组
      _byOperator.clear();
      for (final entry in _byText.entries) {
        final path = entry.value;
        final opId = path.split('/').first;
        _byOperator.putIfAbsent(opId, () => []).add(entry.value);
      }

      _loaded = true;
      _available = _byText.isNotEmpty;

      debugPrint(
        '[VoiceManifest] 加载完成：${_byText.length} 条台词，${_byOperator.length} 位接线员',
      );
      for (final entry in _byOperator.entries) {
        debugPrint('  - ${entry.key}: ${entry.value.length} 条');
      }

      return _available;
    } catch (e) {
      debugPrint('[VoiceManifest] 加载失败（将使用 TTS）：$e');
      _loaded = true;
      _available = false;
      return false;
    }
  }

  /// 检查文本是否有预录制音频
  bool hasAudio(String text) => _byText.containsKey(text);

  /// 获取音频文件路径
  String? getAudioPath(String text) => _byText[text];

  /// 获取接线员的所有音频路径
  List<String>? getOperatorAudios(String opId) => _byOperator[opId];

  /// 检查接线员是否有预录制音频
  bool hasOperatorAudios(String opId) {
    final audios = _byOperator[opId];
    return audios != null && audios.isNotEmpty;
  }

  /// 清除缓存
  void clear() {
    _byText.clear();
    _byOperator.clear();
    _loaded = false;
    _available = false;
  }
}

/// 语音模式枚举
enum VoiceMode {
  /// 纯 TTS 模式（实时合成）
  ttsOnly,

  /// 纯预录制模式（无音频则跳过）
  prerecordedOnly,

  /// 降级模式（优先预录制，无则 TTS）
  fallback,
}

/// 语音模式管理器
///
/// 用于在运行时切换 TTS/预录制模式
class VoiceModeManager {
  static VoiceModeManager? _instance;
  static VoiceModeManager get instance {
    _instance ??= VoiceModeManager._();
    return _instance!;
  }

  VoiceModeManager._();

  VoiceMode _mode = VoiceMode.fallback;
  bool _initialized = false;

  /// 当前模式
  VoiceMode get mode => _mode;

  /// 是否使用预录制优先
  bool get isPrerecordedPreferred =>
      _mode == VoiceMode.prerecordedOnly || _mode == VoiceMode.fallback;

  /// 是否纯 TTS 模式
  bool get isTtsOnly => _mode == VoiceMode.ttsOnly;

  /// 初始化并检测可用模式
  ///
  /// 如果 [kUsePrerecordedVoiceOnly] 为 true，则强制使用预录制模式
  Future<void> initialize() async {
    if (_initialized) return;

    // 编译时配置：强制预录制模式
    if (kUsePrerecordedVoiceOnly) {
      _mode = VoiceMode.prerecordedOnly;
      debugPrint('[VoiceMode] 编译配置：强制预录制模式');
      _initialized = true;
      return;
    }

    final manifestAvailable = await VoiceManifest.instance.load();

    if (!manifestAvailable) {
      _mode = VoiceMode.ttsOnly;
      debugPrint('[VoiceMode] 无预录制资源，使用 TTS 模式');
    } else {
      _mode = VoiceMode.fallback;
      debugPrint('[VoiceMode] 预录制资源可用，使用降级模式');
    }

    _initialized = true;
  }

  /// 切换模式
  void setMode(VoiceMode mode) {
    _mode = mode;
    debugPrint('[VoiceMode] 切换到模式：$mode');
  }

  /// 检查指定接线员是否有预录制音频
  bool hasPrerecordedForOperator(String opId) {
    return VoiceManifest.instance.hasOperatorAudios(opId);
  }

  /// 获取推荐模式
  VoiceMode get recommendedMode {
    if (!VoiceManifest.instance.isAvailable) {
      return VoiceMode.ttsOnly;
    }
    return VoiceMode.fallback;
  }
}
