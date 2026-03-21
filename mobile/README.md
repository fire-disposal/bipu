# BIPUPU Mobile

一款蓝牙传呼机应用 - Flutter 版本

## 📦 iOS 打包文档索引

### 快速开始（推荐）

| 文档 | 用途 | 适合场景 |
|------|------|----------|
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | 🚀 快速参考卡片 | 熟悉流程后快速查阅 |
| **[REMOTE_MAC_SETUP_GUIDE.md](REMOTE_MAC_SETUP_GUIDE.md)** | 📋 远程操作指南 | 远程操作朋友 Mac 电脑 |

### 详细文档

| 文档 | 用途 |
|------|------|
| **[IOS_BUILD_REPORT.md](IOS_BUILD_REPORT.md)** | 📊 完整的 iOS 打包适配性检测报告 |
| **[ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md](ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md)** | 📝 临时账户打包详细步骤 |

### 自动化脚本

| 脚本 | 功能 |
|------|------|
| `setup_ios_temporary_build.sh` | 设置 Bundle ID 和签名配置 |
| `ios_quick_build.sh` | 一键检测环境并运行 |

---

## 🎯 远程打包简化流程

```bash
# 1. 进入项目目录
cd /path/to/bipupu/mobile

# 2. 运行设置脚本（输入 Bundle ID）
./setup_ios_temporary_build.sh

# 3. 打开 Xcode
open ios/Runner.xcworkspace

# 4. 在 Xcode 中配置签名（选择 Apple ID）
# 5. 选择真机并运行
```

详细步骤请查看 **[REMOTE_MAC_SETUP_GUIDE.md](REMOTE_MAC_SETUP_GUIDE.md)**

---

## 📱 功能特性

- 🔵 蓝牙设备扫描和连接
- 🎤 语音识别和 TTS
- 📸 头像设置（相机/相册）
- 🔔 消息通知
- 📡 实时通信

---

## 🛠 开发环境

- Flutter SDK: ^3.10.1
- iOS: 13.0+
- Android: 5.0+

---

## 📄 许可证

Copyright © 2026 BIPUPU Team
