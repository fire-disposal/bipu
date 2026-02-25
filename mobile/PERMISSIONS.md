# 权限配置说明

本文档详细说明了 Bipupu 移动应用所需的权限及其用途。

## 概述

Bipupu 应用需要多种权限以支持其核心功能，包括语音识别、蓝牙连接、网络状态监测、文件存储、通知推送和图像处理等。

## Android 权限配置

### AndroidManifest.xml 中的权限声明

以下权限已在 `android/app/src/main/AndroidManifest.xml` 中声明：

#### 1. 麦克风权限
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```
**用途**：用于语音识别（ASR）功能，允许应用访问设备的麦克风以录制音频。

#### 2. 蓝牙权限
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```
**用途**：用于蓝牙功能，允许应用扫描、连接和管理蓝牙设备。

#### 3. 网络权限
```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```
**用途**：
- `ACCESS_NETWORK_STATE` 和 `ACCESS_WIFI_STATE`：用于监测网络连接状态
- `INTERNET`：允许应用访问互联网（如果应用需要网络功能）

#### 4. 位置权限
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
**用途**：Android 12+ 需要位置权限来扫描附近的蓝牙设备。这是蓝牙扫描功能的必要条件。

#### 5. 通知权限
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```
**用途**：Android 13+ 需要明确请求通知权限，用于推送本地通知。

#### 6. 存储权限
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```
**用途**：用于读写模型文件和音频文件，包括：
- 将 TTS/ASR 模型文件从 assets 复制到本地存储
- 保存生成的音频文件
- 读取用户选择的图片

#### 7. 相机权限
```xml
<uses-permission android:name="android.permission.CAMERA" />
```
**用途**：用于拍照和扫描二维码功能。

### 特殊配置

```xml
android:requestLegacyExternalStorage="true"
```
**用途**：在 application 标签中添加此属性以支持 Android 10+ 的存储访问框架。

## iOS 权限配置

### Info.plist 中的权限声明

以下权限已在 `ios/Runner/Info.plist` 中声明：

#### 1. 麦克风权限
```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风以进行语音识别</string>
```
**用途**：用于语音识别功能，需要向用户说明使用麦克风的目的。

#### 2. 蓝牙权限
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要访问蓝牙以连接设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要访问蓝牙以连接外围设备</string>
```
**用途**：用于蓝牙功能，需要向用户说明使用蓝牙的目的。

#### 3. 后台音频权限
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```
**用途**：允许应用在后台播放音频。

#### 4. 相机权限
```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍照或扫描二维码</string>
```
**用途**：用于拍照和扫描二维码功能。

#### 5. 相册权限
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存图片到相册</string>
```
**用途**：
- `NSPhotoLibraryUsageDescription`：用于从相册选择图片
- `NSPhotoLibraryAddUsageDescription`：用于保存图片到相册

## 权限使用场景

### 1. 语音识别（ASR）功能
- **所需权限**：麦克风权限
- **使用场景**：用户进行语音输入时，应用需要访问麦克风录制音频
- **代码位置**：`lib/core/services/asr_service.dart`

### 2. 文本转语音（TTS）功能
- **所需权限**：存储权限（用于保存模型文件）
- **使用场景**：初始化 TTS 引擎时，需要将模型文件复制到本地存储

### 3. 蓝牙功能
- **所需权限**：蓝牙权限、位置权限（Android）
- **使用场景**：扫描和连接蓝牙设备
- **依赖包**：`flutter_blue_plus`

### 4. 网络状态监测
- **所需权限**：网络状态权限
- **使用场景**：监测设备网络连接状态
- **代码位置**：`lib/core/services/network_service.dart`

### 5. 本地通知
- **所需权限**：通知权限（Android 13+）
- **使用场景**：推送本地通知
- **代码位置**：`lib/core/services/notification_service.dart`

### 6. 图片处理
- **所需权限**：相机权限、相册权限
- **使用场景**：用户选择或拍摄图片
- **依赖包**：`image_picker`, `image_cropper`

## 权限请求时机

### Android
1. **运行时权限**：以下权限需要在运行时请求用户授权：
   - 麦克风权限（RECORD_AUDIO）
   - 位置权限（ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION）
   - 存储权限（READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE）
   - 相机权限（CAMERA）
   - 通知权限（POST_NOTIFICATIONS） - Android 13+

2. **安装时权限**：以下权限在安装时自动授予：
   - 蓝牙权限
   - 网络权限
   - 互联网权限

### iOS
所有权限都在首次使用时通过系统弹窗请求用户授权。

## 测试建议

### Android 测试
1. **测试不同 Android 版本**：
   - Android 10-12：测试存储权限
   - Android 13+：测试通知权限
   - 所有版本：测试运行时权限请求

2. **测试权限拒绝场景**：
   - 拒绝麦克风权限后，语音识别功能应优雅降级
   - 拒绝存储权限后，文件操作应有适当的错误处理
   - 拒绝位置权限后，蓝牙扫描功能应有限制

### iOS 测试
1. **测试权限弹窗**：
   - 确保每个权限请求都有合理的描述
   - 测试用户拒绝权限后的应用行为

2. **测试后台音频**：
   - 验证应用在后台时音频播放是否正常

## 故障排除

### 常见问题

1. **Android 蓝牙扫描失败**
   - 确保已添加位置权限
   - 检查 Android 版本是否 >= 12
   - 验证用户已授予位置权限

2. **iOS 后台音频被中断**
   - 确保已添加 `UIBackgroundModes` 中的 `audio` 权限
   - 检查音频会话配置

3. **权限请求不显示**
   - 检查权限声明是否正确
   - 验证权限描述字符串不为空
   - 确保在正确的时机请求权限

### 调试建议

1. 使用 `adb shell pm list permissions` 查看应用权限
2. 使用 Android Studio 的 Profiler 监控权限请求
3. 在 iOS 设备设置中查看应用的权限状态

## 更新记录

| 日期 | 版本 | 变更说明 |
|------|------|----------|
| 2024-01-01 | 1.0.0 | 初始权限配置 |
| 2024-01-26 | 1.1.0 | 添加 TTS/ASR 相关权限 |
| 2024-01-26 | 1.2.0 | 添加蓝牙和位置权限 |

## 参考链接

1. [Android 权限指南](https://developer.android.com/guide/topics/permissions/overview)
2. [iOS 权限指南](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
3. [Flutter 权限处理](https://pub.dev/packages/permission_handler)
4. [Android 蓝牙权限要求](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions)

---

**注意**：在发布应用前，请确保所有权限请求都有合理的用户说明，并且应用在权限被拒绝时能够优雅降级。