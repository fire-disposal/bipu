# iOS 打包适配性检测报告

**项目**: BIPUPU  
**检测日期**: 2026 年 3 月 21 日  
**检测类型**: 临时账户打包适配性检查

---

## 📊 检测结果总览

| 类别 | 已通过 | 需优化 | 状态 |
|------|--------|--------|------|
| **基础配置** | 5 | 0 | ✅ |
| **权限配置** | 7 | 1 | ⚠️ |
| **签名配置** | 0 | 3 | ✅ 已优化 |
| **后台模式** | 3 | 0 | ✅ |
| **依赖插件** | 11 | 0 | ✅ |

**总体评估**: ✅ 适配性良好，已完成优化

---

## ✅ 已验证的配置项

### 1. 基础配置

| 配置项 | 当前值 | 要求 | 状态 |
|--------|--------|------|------|
| 最小 iOS 版本 | 13.0 | ≥12.0 | ✅ |
| Bundle ID 格式 | com.bipupu.user.flutterUser | 有效格式 | ✅ |
| 应用名称 | BIPUPU | - | ✅ |
| 版本号 | $(FLUTTER_BUILD_NAME) | 动态配置 | ✅ |
| 构建号 | $(FLUTTER_BUILD_NUMBER) | 动态配置 | ✅ |

### 2. 权限描述 (Info.plist)

| 权限 | Key | 描述文案 | 状态 |
|------|-----|----------|------|
| 麦克风 | NSMicrophoneUsageDescription | This app needs access to microphone for speech recognition. | ✅ |
| 相册 | NSPhotoLibraryUsageDescription | 我们需要访问您的相册以设置头像 | ✅ |
| 相机 | NSCameraUsageDescription | 我们需要使用您的相机以拍摄头像照片 | ✅ |
| 蓝牙 (始终) | NSBluetoothAlwaysUsageDescription | Need Bluetooth to connect to pager devices. | ✅ |
| 蓝牙 (外设) | NSBluetoothPeripheralUsageDescription | Need Bluetooth to connect to pager devices. | ✅ |
| 定位 (始终) | NSLocationAlwaysUsageDescription | Need Location to scan for devices in background. | ✅ |
| 定位 (使用中) | NSLocationWhenInUseUsageDescription | Need Location to scan for devices. | ✅ |
| 通知 | NSUserNotificationUsageDescription | 我们需要通知权限以提醒您收到新消息 | ✅ (新增) |

### 3. 后台模式 (UIBackgroundModes)

| 模式 | 值 | 用途 | 状态 |
|------|-----|------|------|
| 蓝牙中央 | bluetooth-central | 连接蓝牙设备 | ✅ |
| 蓝牙外设 | bluetooth-peripheral | 作为蓝牙外设 | ✅ (新增) |
| 后台获取 | fetch | 后台数据更新 | ✅ |
| 后台处理 | processing | 后台任务处理 | ✅ |
| 远程通知 | remote-notification | 推送通知 | ✅ (新增) |

### 4. 依赖插件兼容性

| 插件 | 版本 | iOS 兼容性 | 状态 |
|------|------|-----------|------|
| flutter_blue_plus | ^2.0.2 | ✅ 支持 iOS 13+ | ✅ |
| permission_handler | ^12.0.1 | ✅ 支持 iOS 13+ | ✅ |
| flutter_local_notifications | ^21.0.0 | ✅ 支持 iOS 13+ | ✅ |
| image_picker | ^1.1.2 | ✅ 支持 iOS 13+ | ✅ |
| speech_to_text | ^7.3.0 | ✅ 支持 iOS 13+ | ✅ |
| just_audio | ^0.10.5 | ✅ 支持 iOS 13+ | ✅ |
| flutter_secure_storage | ^10.0.0 | ✅ 支持 iOS 13+ | ✅ |
| path_provider | ^2.1.2 | ✅ 支持 iOS 13+ | ✅ |
| cached_network_image | ^3.4.1 | ✅ 支持 iOS 13+ | ✅ |
| flutter_background_service | ^5.1.0 | ✅ 支持 iOS 13+ | ✅ |
| connectivity_plus | ^7.0.0 | ✅ 支持 iOS 13+ | ✅ |

---

## 🔧 已完成的优化

### 1. 创建 Entitlements 文件

**文件**: `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.device.bluetooth-central</key>
	<true/>
	<key>com.apple.security.device.bluetooth-peripheral</key>
	<true/>
</dict>
</plist>
```

### 2. 更新 Xcode 项目配置

**文件**: `ios/Runner.xcodeproj/project.pbxproj`

- ✅ 添加 Runner.entitlements 文件引用
- ✅ 配置 Debug/Release/Profile 的 `CODE_SIGN_ENTITLEMENTS`
- ✅ 配置 `CODE_SIGN_STYLE = Automatic`

### 3. 增强 Info.plist 配置

- ✅ 添加 `bluetooth-peripheral` 后台模式
- ✅ 添加 `remote-notification` 后台模式
- ✅ 添加 `NSUserNotificationUsageDescription`

---

## 📝 临时账户打包步骤

### 前置准备

1. **修改 Bundle ID** (避免冲突)
   
   编辑 `ios/Runner.xcodeproj/project.pbxproj`:
   ```
   PRODUCT_BUNDLE_IDENTIFIER = com.你的标识.bipupu;
   ```

2. **打开 Xcode 项目**
   ```bash
   cd mobile
   open ios/Runner.xcworkspace
   ```

### Xcode 配置

1. **选择 Runner Target** → **Signing & Capabilities**

2. **配置签名**:
   - ✅ Automatically manage signing
   - Team: 选择你的 Apple ID
   - Bundle Identifier: 确认与修改的一致

3. **添加 Capabilities**:
   - Background Modes
     - ✅ Acts as a BLE Central
     - ✅ Acts as a BLE Peripheral
     - ✅ Remote notifications

### 构建运行

```bash
cd mobile
flutter clean
flutter pub get
flutter run  # 选择真机
```

---

## ⚠️ 注意事项

### 临时账户限制

| 功能 | 免费账户 | 说明 |
|------|---------|------|
| 真机调试 | ✅ 7 天有效期 | 每 7 天需重新签名 |
| App Store 发布 | ❌ | 需付费开发者账户 |
| TestFlight | ❌ | 需付费开发者账户 |
| Push Notifications | ⚠️ 仅限真机 | 需要付费账户才能配置 APNs |
| iCloud | ❌ | 需付费开发者账户 |

### 蓝牙功能特别说明

- ⚠️ **模拟器不支持蓝牙** - 必须使用真机测试
- ✅ 蓝牙权限已在代码中正确请求 (`bluetooth_scan_page.dart`)
- ✅ 后台扫描需要定位权限配合

### 通知权限说明

- iOS 13+ 需要运行时请求通知权限
- `notification_service.dart` 已实现权限请求逻辑
- 首次显示通知时会自动请求权限

---

## 🔍 常见问题排查

### 问题 1: 签名证书找不到

**错误**: "No signing certificate found"

**解决**:
1. Xcode → Settings → Accounts
2. 选择 Apple ID → Manage Certificates
3. 添加 "iOS Signing" 证书
4. 重启 Xcode

### 问题 2: Bundle ID 冲突

**错误**: "An application with this identifier already exists"

**解决**: 修改 Bundle ID 为更唯一的标识
```
com.你的邮箱前缀.bipupu
```

### 问题 3: 蓝牙无法扫描

**检查清单**:
- [ ] 使用真机运行
- [ ] 设备蓝牙已开启
- [ ] 已授予蓝牙和定位权限
- [ ] Info.plist 包含所有蓝牙权限描述
- [ ] Runner.entitlements 文件存在

### 问题 4: 应用启动后 7 天过期

**说明**: 这是免费账户的正常限制

**解决**: 
- 重新连接 Xcode 并重新运行
- 或使用脚本自动重新签名

---

## 📋 打包前检查清单

- [ ] Bundle ID 已修改为唯一标识
- [ ] Xcode 已登录 Apple ID
- [ ] 自动签名已启用
- [ ] Runner.entitlements 文件存在
- [ ] Info.plist 权限描述完整
- [ ] Background Modes 已配置
- [ ] 使用真机测试（蓝牙功能）
- [ ] 应用能在真机上成功启动
- [ ] 蓝牙扫描和连接功能正常
- [ ] 通知权限请求正常

---

## 📁 修改文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `ios/Runner/Runner.entitlements` | ✅ 新建 | 蓝牙权限配置文件 |
| `ios/Runner/Info.plist` | ✅ 更新 | 添加通知权限和后台模式 |
| `ios/Runner.xcodeproj/project.pbxproj` | ✅ 更新 | 添加签名配置 |
| `ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md` | ✅ 新建 | 临时账户打包详细指南 |
| `IOS_BUILD_REPORT.md` | ✅ 新建 | 本报告 |

---

## ✅ 结论

项目 iOS 打包适配性**良好**，所有必要的权限配置和签名配置已完成优化。

**可以开始使用临时账户进行打包测试**。

详细打包步骤请参考：`ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md`
