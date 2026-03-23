# 🚀 iOS 打包快速参考卡片

## 📋 远程操作朋友 Mac 的简化流程

### 1️⃣ 让朋友准备
- [ ] Apple ID（没有就先注册）
- [ ] Xcode 已安装（App Store 下载）
- [ ] Flutter 已安装
- [ ] iPhone 用数据线连接

### 2️⃣ 运行脚本（你操作）

```bash
# 进入项目目录
cd /path/to/bipupu/mobile

# 运行设置脚本
./setup_ios_temporary_build.sh
# 输入 Bundle ID，如：com.friend.bipupu

# 打开 Xcode
open ios/Runner.xcworkspace
```

### 3️⃣ Xcode 配置（你指导朋友）

```
1. 左侧选择 "Runner" 项目
2. 选择 TARGETS → Runner
3. 选择 "Signing & Capabilities"
4. 勾选 "Automatically manage signing"
5. Team 选择朋友的 Apple ID 
6. 如果没有，点 "Add Account" 登录
```

### 4️⃣ 运行应用

**方法 A：Xcode 中运行**
```
1. 顶部选择朋友的 iPhone
2. 点击运行按钮 ▶️
```

**方法 B：命令行运行**
```bash
flutter clean
flutter pub get
flutter run
```

### 5️⃣ iPhone 信任开发者

```
设置 → 通用 → VPN 与设备管理
找到朋友的邮箱 → 信任
```

---

## ⚡ 常用命令速查

```bash
# 设置 Bundle ID
./setup_ios_temporary_build.sh

# 一键运行
./ios_quick_build.sh

# 查看设备
flutter devices

# 清理并运行
flutter clean && flutter run

# 打开 Xcode
open ios/Runner.xcworkspace
```

---

## ⚠️ 常见问题速查

| 问题 | 解决方法 |
|------|----------|
| No signing certificate | Xcode → Accounts → Manage Certificates → 添加 iOS Signing |
| 找不到设备 | 检查数据线、信任电脑、解锁 iPhone |
| 蓝牙不可用 | 必须用真机，模拟器不支持蓝牙 |
| 应用打不开 | 设置 → 通用 → 设备管理 → 信任开发者 |
| 7 天后过期 | 重新运行 `flutter run` 即可 |

---

## 📞 远程协助建议

1. **使用屏幕共享**：腾讯会议/钉钉/FaceTime
2. **保持语音通话**：微信电话/手机通话
3. **关键步骤朋友操作**：如输入 Apple ID 密码
4. **使用屏幕标注**：指示点击位置

---

## ✅ 成功标志

- ✅ Xcode 显示 "Runner.app installed"
- ✅ iPhone 出现 BIPUPU 图标
- ✅ 应用能正常启动
- ✅ 能扫描蓝牙设备

---

## 📁 重要文件

| 文件 | 用途 |
|------|------|
| `setup_ios_temporary_build.sh` | 设置 Bundle ID |
| `ios_quick_build.sh` | 一键运行 |
| `REMOTE_MAC_SETUP_GUIDE.md` | 详细指南 |
| `IOS_BUILD_REPORT.md` | 检测报告 |
| `ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md` | 打包指南 |

---

## 💡 提示

- **首次配置需 10-15 分钟**（下载证书等）
- **必须使用真机**（模拟器无蓝牙）
- **7 天后需重新签名**（正常现象）
- **保持网络畅通**（连接 Apple 服务器）
