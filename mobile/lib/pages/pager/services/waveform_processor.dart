import 'dart:math' as math;
import '../../../core/utils/logger.dart';

/// 波形数据处理器
/// 负责从音频数据中提取波形包络，进行预处理（去除静默/噪声），
/// 并转换为 0-255 的振幅值用于消息发送
class WaveformProcessor {
  // 波形数据缓冲区
  final List<int> _waveformBuffer = [];
  final List<double> _volumeBuffer = [];

  // 配置参数
  static const int maxWaveformPoints = 128; // 最多128个点
  static const int silenceThreshold = 500; // 静默阈值（PCM值）
  static const int noiseFloor = 300; // 噪声底线
  static const double silenceRatio = 0.1; // 允许的静默比例（10%）

  /// 从PCM音频数据中提取波形包络
  ///
  /// [pcmData]: 16-bit PCM音频数据
  /// [sampleRate]: 采样率（Hz）
  /// [frameSize]: 每帧的样本数（用于计算包络）
  List<int> extractWaveform(
    List<int> pcmData, {
    int sampleRate = 16000,
    int frameSize = 512,
  }) {
    if (pcmData.isEmpty) {
      return [];
    }

    try {
      // 1. 将PCM数据分帧并计算每帧的RMS能量
      final frameEnergies = _calculateFrameEnergies(pcmData, frameSize);

      if (frameEnergies.isEmpty) {
        return [];
      }

      // 2. 检测静默段并去除开头和结尾的静默
      final trimmedEnergies = _trimSilence(frameEnergies);

      if (trimmedEnergies.isEmpty) {
        logger.w('No valid audio data after silence trimming');
        return [];
      }

      // 3. 归一化能量值到 0-255 范围
      final normalizedEnergies = _normalizeToByteRange(trimmedEnergies);

      // 4. 下采样到最多128个点
      final downsampled = _downsample(normalizedEnergies, maxWaveformPoints);

      logger.i('Waveform extracted: ${downsampled.length} points');
      return downsampled;
    } catch (e) {
      logger.e('Error extracting waveform: $e');
      return [];
    }
  }

  /// 计算每帧的RMS能量
  List<double> _calculateFrameEnergies(List<int> pcmData, int frameSize) {
    final energies = <double>[];

    for (int i = 0; i < pcmData.length; i += frameSize) {
      final frameEnd = (i + frameSize).clamp(0, pcmData.length);
      final frame = pcmData.sublist(i, frameEnd);

      // 计算RMS（均方根）
      double sumSquares = 0;
      for (final sample in frame) {
        sumSquares += sample * sample;
      }

      final rms = (sumSquares / frame.length).isFinite
          ? math.sqrt(sumSquares / frame.length)
          : 0.0;

      energies.add(rms);
    }

    return energies;
  }

  /// 去除开头和结尾的静默
  ///
  /// 使用简单的阈值检测：
  /// - 从开头找到第一个超过阈值的帧
  /// - 从结尾找到最后一个超过阈值的帧
  /// - 返回中间部分
  List<double> _trimSilence(List<double> energies) {
    if (energies.isEmpty) {
      return [];
    }

    // 计算平均能量作为动态阈值
    final avgEnergy = energies.reduce((a, b) => a + b) / energies.length;
    final threshold = (avgEnergy * 0.3).clamp(
      silenceThreshold.toDouble(),
      double.infinity,
    );

    // 从开头找到第一个超过阈值的帧
    int startIdx = 0;
    for (int i = 0; i < energies.length; i++) {
      if (energies[i] > threshold) {
        startIdx = i;
        break;
      }
    }

    // 从结尾找到最后一个超过阈值的帧
    int endIdx = energies.length - 1;
    for (int i = energies.length - 1; i >= 0; i--) {
      if (energies[i] > threshold) {
        endIdx = i;
        break;
      }
    }

    // 确保至少保留一些数据
    if (startIdx > endIdx) {
      return energies;
    }

    // 允许在开头和结尾保留一些静默（用于自然过渡）
    final allowedSilenceFrames = (energies.length * silenceRatio).toInt();
    startIdx = (startIdx - allowedSilenceFrames).clamp(0, energies.length - 1);
    endIdx = (endIdx + allowedSilenceFrames).clamp(0, energies.length - 1);

    return energies.sublist(startIdx, endIdx + 1);
  }

  /// 归一化能量值到 0-255 范围
  List<int> _normalizeToByteRange(List<double> energies) {
    if (energies.isEmpty) {
      return [];
    }

    // 找到最大值
    final maxEnergy = energies.reduce((a, b) => a > b ? a : b);

    if (maxEnergy == 0) {
      return List.filled(energies.length, 0);
    }

    // 归一化到 0-255
    return energies.map((energy) {
      final normalized = (energy / maxEnergy * 255).toInt();
      return normalized.clamp(0, 255);
    }).toList();
  }

  /// 下采样到指定的点数
  ///
  /// 使用最大值采样法：将数据分成N个段，
  /// 每段取最大值，保留音频的峰值特征
  List<int> _downsample(List<int> data, int targetPoints) {
    if (data.length <= targetPoints) {
      return data;
    }

    final result = <int>[];
    final segmentSize = data.length / targetPoints;

    for (int i = 0; i < targetPoints; i++) {
      final startIdx = (i * segmentSize).toInt();
      final endIdx = ((i + 1) * segmentSize).toInt().clamp(0, data.length);

      if (startIdx >= data.length) break;

      // 取该段的最大值
      final maxValue = data
          .sublist(startIdx, endIdx)
          .reduce((a, b) => a > b ? a : b);
      result.add(maxValue);
    }

    return result;
  }

  /// 添加PCM数据到缓冲区
  ///
  /// 用于实时录音过程中持续收集音频数据
  void addPcmData(List<int> pcmData) {
    _waveformBuffer.addAll(pcmData);
  }

  /// 添加音量数据
  ///
  /// 用于从ASR引擎的实时音量数据生成波形
  void addVolumeData(double volume) {
    _volumeBuffer.add(volume);
  }

  /// 从音量数据生成波形
  ///
  /// 将音量数据转换为波形点
  List<double> getWaveformFromVolume() {
    if (_volumeBuffer.isEmpty) {
      return [];
    }

    // 限制波形点数
    final targetPoints = math.min(_volumeBuffer.length, maxWaveformPoints);

    // 如果数据点太多，进行下采样
    if (_volumeBuffer.length > targetPoints) {
      final downsampled = <double>[];
      final segmentSize = _volumeBuffer.length / targetPoints;

      for (int i = 0; i < targetPoints; i++) {
        final startIdx = (i * segmentSize).toInt();
        final endIdx = ((i + 1) * segmentSize).toInt().clamp(
          0,
          _volumeBuffer.length,
        );

        if (startIdx >= _volumeBuffer.length) break;

        // 取该段的最大值
        final maxValue = _volumeBuffer
            .sublist(startIdx, endIdx)
            .reduce((a, b) => a > b ? a : b);
        downsampled.add(maxValue);
      }

      return downsampled;
    }

    return List.from(_volumeBuffer);
  }

  /// 获取当前缓冲区的波形数据
  ///
  /// 返回已处理的波形包络（0-255）
  List<int> getCurrentWaveform({int frameSize = 512}) {
    if (_waveformBuffer.isEmpty) {
      return [];
    }

    return extractWaveform(_waveformBuffer, frameSize: frameSize);
  }

  /// 清空缓冲区
  void clear() {
    _waveformBuffer.clear();
    _volumeBuffer.clear();
  }

  /// 获取缓冲区大小（字节数）
  int getBufferSize() {
    return _waveformBuffer.length;
  }

  /// 获取缓冲区中的PCM数据
  List<int> getBufferData() {
    return List.from(_waveformBuffer);
  }

  /// 完成录音并返回最终的波形数据
  ///
  /// 这个方法应该在录音结束时调用，
  /// 确保返回的波形数据已正确处理和封装
  List<int> finalize({int frameSize = 512}) {
    final waveform = getCurrentWaveform(frameSize: frameSize);
    logger.i(
      'Waveform finalized: ${waveform.length} points, buffer size: ${_waveformBuffer.length}',
    );
    return waveform;
  }
}

/// 波形数据验证器
/// 确保波形数据的有效性
class WaveformValidator {
  /// 验证波形数据
  ///
  /// 检查：
  /// - 数据不为空
  /// - 所有值在 0-255 范围内
  /// - 数据点数不超过128
  static bool isValid(List<int>? waveform) {
    if (waveform == null || waveform.isEmpty) {
      return false;
    }

    if (waveform.length > 128) {
      logger.w('Waveform has too many points: ${waveform.length}');
      return false;
    }

    for (final value in waveform) {
      if (value < 0 || value > 255) {
        logger.w('Invalid waveform value: $value');
        return false;
      }
    }

    return true;
  }

  /// 获取波形数据的统计信息
  static Map<String, dynamic> getStats(List<int> waveform) {
    if (waveform.isEmpty) {
      return {'count': 0, 'min': 0, 'max': 0, 'avg': 0.0, 'valid': false};
    }

    final min = waveform.reduce((a, b) => a < b ? a : b);
    final max = waveform.reduce((a, b) => a > b ? a : b);
    final avg = waveform.reduce((a, b) => a + b) / waveform.length;

    return {
      'count': waveform.length,
      'min': min,
      'max': max,
      'avg': avg,
      'valid': isValid(waveform),
    };
  }
}

/// 波形数据编码器
/// 将波形数据编码为消息格式
class WaveformEncoder {
  /// 将波形数据编码为字节数组
  ///
  /// 格式：[长度(1字节)] + [数据(N字节)]
  static List<int> encode(List<int> waveform) {
    if (!WaveformValidator.isValid(waveform)) {
      logger.w('Invalid waveform data, returning empty');
      return [];
    }

    final encoded = <int>[];

    // 添加长度信息
    encoded.add(waveform.length);

    // 添加波形数据
    encoded.addAll(waveform);

    return encoded;
  }

  /// 从字节数组解码波形数据
  static List<int> decode(List<int> encoded) {
    if (encoded.isEmpty) {
      return [];
    }

    final length = encoded[0];

    if (encoded.length < length + 1) {
      logger.w('Invalid encoded waveform data');
      return [];
    }

    return encoded.sublist(1, length + 1);
  }
}
