import 'package:equatable/equatable.dart';

/// 文本处理结果
class TextProcessingResult extends Equatable {
  /// 处理后的文本
  final String processedText;

  /// 是否为有效文本
  final bool isValid;

  /// 验证消息
  final String? validationMessage;

  const TextProcessingResult({
    required this.processedText,
    required this.isValid,
    this.validationMessage,
  });

  @override
  List<Object?> get props => [processedText, isValid, validationMessage];
}

/// 文本处理服务
/// 负责文本内容的验证和处理
class TextProcessor {
  /// 最大消息长度
  static const int maxMessageLength = 160;

  /// 处理文本：去除首尾空格，并进行基础清理
  static TextProcessingResult processText(String text) {
    final processedText = _preprocessText(text);
    final validationMsg = getValidationMessage(processedText);

    return TextProcessingResult(
      processedText: processedText,
      isValid: validationMsg == null,
      validationMessage: validationMsg,
    );
  }

  /// 预处理文本（内部方法）
  static String _preprocessText(String text) {
    // 基础清理：移除首尾空格，将连续空白字符替换为单个空格
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 验证文本内容
  static bool validateContent(String text) {
    if (text.isEmpty) return false;
    if (text.length > maxMessageLength) return false;
    return true;
  }

  /// 获取验证消息
  static String? getValidationMessage(String text) {
    if (text.isEmpty) {
      return '文本不能为空';
    }
    if (text.length > maxMessageLength) {
      return '文本长度不能超过 $maxMessageLength 个字符';
    }
    return null;
  }

  /// 清理文本
  static String sanitizeText(String text) {
    return text.trim();
  }

  /// 格式化消息显示
  static String formatForDisplay(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
