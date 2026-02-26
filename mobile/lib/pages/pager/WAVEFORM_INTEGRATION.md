# 波形数据集成指南

## 概述

本文档说明如何在拨号页面中集成波形数据处理，确保在录音过程中持续收集音频数据，并在发送消息时正确封装波形包络。

## 波形处理流程

### 1. 初始化阶段

```dart
// 在 PagerCubit 中自动初始化
final WaveformProcessor _waveformProcessor = WaveformProcessor();
```

### 2. 录音阶段

在 ASR 录音过程中，持续添加 PCM 音频数据：

```dart
// 从音频流中获取 PCM 数据
void _handleAudioData(List<int> pcmData) {
  // 添加到波形处理器
  cubit.addAudioData(pcmData);
}
```

### 3. 处理阶段

当录音结束时，自动处理波形数据：

```dart
// 在 _stopAsrAndFinalize() 中调用
_currentWaveformData = _waveformProcessor.finalize();

// 验证波形数据
if (!WaveformValidator.isValid(_currentWaveformData)) {
  logger.w('Waveform data is invalid');
  _currentWaveformData = [];
}
```

### 4. 发送阶段

在发送消息时，将波形数据包含在请求中：

```dart
await _apiClient.api.messages.postApiMessages(
  body: MessageCreate(
    receiverId: targetId,
    content: messageContent,
    messageType: MessageType.voice,
    waveform: _currentWaveformData.isEmpty ? null : _currentWaveformData,
  ),
);
```

## 波形处理算法

### 步骤 1: 分帧计算能量

将 PCM 数据分成固定大小的帧（默认 512 样本），计算每帧的 RMS（均方根）能量：

```
RMS = sqrt(sum(sample²) / frame_size)
```

### 步骤 2: 静默检测和去除

使用动态阈值检测静默段：

```
threshold = avg_energy * 0.3

从开头找到第一个超过阈值的帧 (startIdx)
从结尾找到最后一个超过阈值的帧 (endIdx)

允许在开头和结尾保留 10% 的静默用于自然过渡
```

**优势**：
- 自动去除开头和结尾的静默/噪声
- 保留中间的有效语音内容
- 减少无效数据的传输

### 步骤 3: 归一化到 0-255

将能量值映射到 0-255 范围：

```
normalized = (energy / max_energy) * 255
```

### 步骤 4: 下采样到 128 点

使用最大值采样法将数据压缩到最多 128 个点：

```
segment_size = data.length / 128

for each segment:
  max_value = max(segment)
  result.append(max_value)
```

**优势**：
- 保留音频的峰值特征
- 减少数据量（最多 128 字节）
- 适合网络传输

## 数据结构

### 波形数据格式

```
List<int> waveform = [
  0-255,  // 第1个点的振幅
  0-255,  // 第2个点的振幅
  ...
  0-255,  // 第N个点的振幅 (N ≤ 128)
]
```

### 编码格式（可选）

```
[长度(1字节)] + [数据(N字节)]

例如：
[10, 50, 100, 150, 200, 180, 160, 140, 120, 100, 80]
 ↑   ↑   ↑    ↑    ↑    ↑    ↑    ↑    ↑    ↑    ↑
长度 数据点...
```

## 使用示例

### 基础使用

```dart
// 1. 创建处理器
final processor = WaveformProcessor();

// 2. 添加 PCM 数据
processor.addPcmData(pcmData1);
processor.addPcmData(pcmData2);
processor.addPcmData(pcmData3);

// 3. 获取波形数据
final waveform = processor.finalize();

// 4. 验证数据
if (WaveformValidator.isValid(waveform)) {
  // 发送消息
  sendMessage(waveform);
}
```

### 在 Cubit 中使用

```dart
// 在 PagerCubit 中
class PagerCubit extends Cubit<PagerState> {
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  // 添加音频数据
  void addAudioData(List<int> pcmData) {
    _waveformProcessor.addPcmData(pcmData);
  }

  // 发送消息时
  Future<void> sendMessage() async {
    // 获取最终波形数据
    final waveform = _waveformProcessor.finalize();

    // 验证
    if (!WaveformValidator.isValid(waveform)) {
      waveform = [];
    }

    // 发送
    await api.messages.postApiMessages(
      body: MessageCreate(
        receiverId: targetId,
        content: content,
        messageType: MessageType.voice,
        waveform: waveform.isEmpty ? null : waveform,
      ),
    );
  }
}
```

### 实时录音集成

```dart
// 在音频流处理中
_recorderStream?.onAudioFrame = (List<int> audioFrame) {
  // 实时添加到波形处理器
  cubit.addAudioData(audioFrame);

  // 获取当前波形用于UI显示
  final currentWaveform = _waveformProcessor.getCurrentWaveform();
  updateUI(currentWaveform);
};
```

## 配置参数

### WaveformProcessor 配置

```dart
class WaveformProcessor {
  // 最多保留 128 个点
  static const int maxWaveformPoints = 128;

  // 静默阈值（PCM 值）
  static const int silenceThreshold = 500;

  // 噪声底线
  static const int noiseFloor = 300;

  // 允许的静默比例（10%）
  static const double silenceRatio = 0.1;
}
```

### 调整建议

- **增加 `silenceThreshold`**: 更激进地去除静默
- **减少 `silenceRatio`**: 保留更少的边界静默
- **修改 `maxWaveformPoints`**: 调整数据精度（128 是推荐值）

## 错误处理

### 验证波形数据

```dart
// 检查数据有效性
if (!WaveformValidator.isValid(waveform)) {
  logger.w('Invalid waveform data');
  // 发送不带波形的消息
  waveform = [];
}

// 获取统计信息
final stats = WaveformValidator.getStats(waveform);
print('Waveform stats: $stats');
// 输出: {count: 128, min: 0, max: 255, avg: 127.5, valid: true}
```

### 常见问题

**Q: 波形数据为空？**
A: 检查是否有足够的音频数据被添加，或者所有数据都被判定为静默

**Q: 波形数据包含无效值？**
A: 使用 `WaveformValidator.isValid()` 检查，确保所有值在 0-255 范围内

**Q: 波形数据过多或过少？**
A: 调整 `maxWaveformPoints` 参数或 `frameSize` 参数

## 性能考虑

### 内存使用

- 最大波形数据大小: 128 字节
- 缓冲区大小: 取决于录音时长
  - 1 秒 @ 16kHz: ~32KB
  - 5 秒 @ 16kHz: ~160KB

### 处理时间

- 提取波形: ~10-50ms（取决于数据量）
- 验证: <1ms
- 编码: <1ms

### 优化建议

1. **异步处理**: 在后台线程中处理波形
2. **流式处理**: 实时处理而不是等待全部数据
3. **缓存**: 缓存处理结果避免重复计算

## 集成检查清单

- [ ] 导入 `WaveformProcessor` 和 `WaveformValidator`
- [ ] 在 Cubit 中初始化 `_waveformProcessor`
- [ ] 在录音过程中调用 `addAudioData()`
- [ ] 在发送前调用 `finalize()` 获取最终数据
- [ ] 验证波形数据有效性
- [ ] 在 `MessageCreate` 中包含 `waveform` 字段
- [ ] 测试各种场景（静默、噪声、正常语音）
- [ ] 监控日志输出确保数据正确处理

## 测试用例

### 测试 1: 正常语音

```dart
// 模拟 2 秒的语音数据
final pcmData = List.generate(64000, (i) => (math.sin(i / 100) * 1000).toInt());
processor.addPcmData(pcmData);
final waveform = processor.finalize();

// 预期: 128 个点，值在 0-255 范围内
assert(waveform.length <= 128);
assert(waveform.every((v) => v >= 0 && v <= 255));
```

### 测试 2: 静默

```dart
// 模拟 2 秒的静默
final silentData = List.filled(64000, 0);
processor.addPcmData(silentData);
final waveform = processor.finalize();

// 预期: 空或很少的数据
assert(waveform.isEmpty || waveform.length < 10);
```

### 测试 3: 中断恢复

```dart
// 添加部分数据
processor.addPcmData(data1);
processor.addPcmData(data2);

// 获取当前波形（不清空缓冲区）
final current = processor.getCurrentWaveform();

// 继续添加数据
processor.addPcmData(data3);

// 最终化
final final = processor.finalize();

// 预期: final 包含所有数据
assert(final.length >= current.length);
```

## 参考资源

- [PCM 音频格式](https://en.wikipedia.org/wiki/Pulse-code_modulation)
- [RMS 能量计算](https://en.wikipedia.org/wiki/Root_mean_square)
- [音频处理最佳实践](https://developer.android.com/guide/topics/media/audio)
