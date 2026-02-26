# 语音服务初始化指南

## 概述

本文档说明如何在应用中安全地初始化语音服务（ASR 和 TTS），确保与其他服务（认证、网络、蓝牙）的正确协调。

## 初始化时序

### 1. 应用启动顺序（main.dart）

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 第一步：初始化存储
  await StorageManager.initialize();
  
  // 第二步：初始化认证服务
  await AuthService().initialize();
  
  // 第三步：初始化 IM 服务（依赖认证）
  await ImService().initialize();
  
  // 第四步：初始化本地化
  await EasyLocalization.ensureInitialized();
  
  // 第五步：启动应用
  runApp(...);
}
```

### 2. 语音服务初始化时机

语音服务采用**延迟初始化**策略：

```dart
// VoiceService 首次调用时自动初始化
await VoiceService().speak('你好');  // 自动调用 init()

// ASREngine 首次调用时自动初始化
await ASREngine().init();  // 显式初始化

// TTSEngine 首次调用时自动初始化
await TTSEngine().init();  // 显式初始化
```

**优势：**
- 不阻塞应用启动
- 按需加载模型文件
- 减少内存占用

## 服务依赖关系

```
应用启动
  ↓
StorageManager（存储初始化）
  ↓
AuthService（认证初始化）
  ↓
ImService（IM 服务初始化）
  ↓
应用运行
  ↓
VoiceService（按需初始化）
  ├─ TTSEngine（自动初始化）
  │  └─ ModelManager（加载 TTS 模型）
  └─ ASREngine（自动初始化）
     └─ ModelManager（加载 ASR 模型）
```

## 安全初始化检查清单

### ✅ 认证服务（AuthService）

**初始化位置：** `main.dart` 第 67 行
```dart
await AuthService().initialize();
```

**职责：**
- 检查本地 Token 有效性
- 恢复用户认证状态
- 监听 Token 过期事件

**与语音服务的关系：**
- 语音服务不依赖认证
- 但 VoiceService 可在任何认证状态下使用

### ✅ IM 服务（ImService）

**初始化位置：** `main.dart` 第 70 行
```dart
await ImService().initialize();
```

**职责：**
- 启动消息轮询
- 启动联系人轮询
- 监听网络连接状态
- 转发新消息到蓝牙设备

**与语音服务的关系：**
- 两者独立运行
- 可同时使用（例如：接收消息时播放提示音）

### ✅ 蓝牙服务（BluetoothDeviceService）

**初始化位置：** 按需初始化
```dart
final bluetoothService = BluetoothDeviceService();
await bluetoothService.initialize();
```

**职责：**
- 管理蓝牙连接
- 发送/接收蓝牙数据

**与语音服务的关系：**
- 两者独立运行
- 可同时使用（例如：通过蓝牙设备播放语音）

### ✅ 语音服务（VoiceService）

**初始化位置：** 首次调用时自动初始化
```dart
await VoiceService().speak('你好');
```

**职责：**
- 生成语音
- 播放语音
- 管理音频资源

**初始化流程：**
1. 调用 `VoiceService().speak()`
2. 自动调用 `init()`
3. 初始化 TTSEngine
4. 加载 TTS 模型文件
5. 生成并播放语音

## 错误处理

### 认证错误

```dart
try {
  await AuthService().initialize();
} catch (e) {
  logger.e('Auth initialization failed: $e');
  // 应用无法启动
}
```

### 网络错误

```dart
try {
  await ImService().initialize();
} catch (e) {
  logger.e('IM service initialization failed: $e');
  // 应用可继续运行，但消息轮询不可用
}
```

### 语音服务错误

```dart
try {
  await VoiceService().speak('你好');
} catch (e) {
  logger.e('Voice service error: $e');
  // 应用继续运行，语音功能不可用
}
```

## 资源管理

### 音频资源竞争

当 TTS 和 ASR 同时运行时，使用 `AudioResourceManager` 管理资源：

```dart
// VoiceService 内部自动处理
final release = await _audioManager.acquire();
try {
  // 使用音频资源
  await _playAudio(audio);
} finally {
  release();  // 释放资源
}
```

### 模型文件缓存

模型文件首次加载后缓存在本地：

```
应用支持目录/models/
├── asr/
│   ├── encoder-epoch-99-avg-1.int8.onnx
│   ├── decoder-epoch-99-avg-1.onnx
│   ├── joiner-epoch-99-avg-1.int8.onnx
│   └── tokens.txt
└── tts/
    ├── vits-aishell3.onnx
    ├── tokens.txt
    ├── lexicon.txt
    ├── phone.fst
    ├── date.fst
    ├── number.fst
    └── new_heteronym.fst
```

## 最佳实践

### 1. 不要在 main() 中初始化语音服务

❌ **错误做法：**
```dart
Future<void> main() async {
  await VoiceService().init();  // 不要这样做
  runApp(...);
}
```

✅ **正确做法：**
```dart
Future<void> main() async {
  // 只初始化必要的服务
  await AuthService().initialize();
  await ImService().initialize();
  runApp(...);
}

// 在需要时初始化语音服务
await VoiceService().speak('你好');
```

### 2. 处理初始化异常

```dart
try {
  await VoiceService().speak('你好');
} on Exception catch (e) {
  logger.e('Voice service error: $e');
  // 显示用户友好的错误提示
  ToastService().showError('语音功能暂时不可用');
}
```

### 3. 清理资源

```dart
@override
void dispose() {
  VoiceService().dispose();
  super.dispose();
}
```

## 调试

### 启用详细日志

```dart
// 在 main.dart 中
Logger.root.level = Level.ALL;
```

### 检查模型文件

```dart
final modelPath = ModelManager.instance.getModelPath('asr/encoder-epoch-99-avg-1.int8.onnx');
logger.i('Model path: $modelPath');
```

### 监听初始化事件

```dart
// VoiceService 初始化时会输出日志
// I/flutter: VoiceService initialized
```

## 常见问题

### Q: 为什么语音服务初始化很慢？

A: 首次初始化需要从 assets 拷贝大型模型文件（数十 MB）到本地。后续调用会使用缓存，速度会快得多。

### Q: 可以同时使用 TTS 和 ASR 吗？

A: 可以，但需要通过 `AudioResourceManager` 管理音频资源。VoiceService 已自动处理。

### Q: 如何更新模型文件？

A: 修改 `VoiceConfig` 中的模型文件名，然后清除应用数据重新启动。

### Q: 语音服务会占用多少内存？

A: 模型文件加载后约占用 200-300 MB 内存。使用 `dispose()` 可释放资源。
