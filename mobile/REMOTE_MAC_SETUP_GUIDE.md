# 远程 Mac 打包 iOS 操作指南

**适用场景**: 远程操作朋友的 Mac 电脑进行 iOS 打包  
**目标**: 使用临时 Apple ID 账户打包测试

---

## 📋 准备工作清单

### 远程连接前请朋友准备

请朋友提前准备好以下内容：

1. **Apple ID**
   - 如果没有，先注册一个（免费）
   - 记住账号和密码

2. **安装必要软件**
   ```bash
   # 检查是否已安装 Xcode
   xcodebuild -version
   
   # 检查是否已安装 Flutter
   flutter --version
   ```
   
3. **如果未安装 Flutter**，请朋友运行：
   ```bash
   # 使用 Homebrew 安装（推荐）
   brew install --cask flutter
   
   # 或者手动安装
   # 下载：https://docs.flutter.dev/get-started/install/macos
   ```

4. **如果未安装 Xcode**，请朋友运行：
   ```bash
   # App Store 下载 Xcode
   # 搜索 "Xcode" 并安装（约 12GB）
   ```

5. **连接 iPhone**
   - 用数据线连接 iPhone 到 Mac
   - 在 iPhone 上信任此电脑

---

## 🔧 远程操作步骤

### 步骤 1: 进入项目目录

```bash
cd /path/to/bipupu/mobile
# 例如：cd ~/Desktop/bipupu/mobile
```

### 步骤 2: 运行设置脚本

```bash
# 赋予执行权限
chmod +x setup_ios_temporary_build.sh

# 运行脚本（交互式）
./setup_ios_temporary_build.sh
```

脚本会提示输入 Bundle ID，可以输入：
```
com.朋友的名字.bipupu
```
例如：`com.john.bipupu` 或 `com.firedisposal.bipupu`

### 步骤 3: 打开 Xcode 项目

```bash
open ios/Runner.xcworkspace
```

### 步骤 4: 在 Xcode 中配置签名

**在 Xcode 中操作**：

1. **左侧项目导航** → 选择 **Runner** (最上方的蓝色图标)

2. **顶部标签** → 选择 **TARGETS** 下的 **Runner**

3. **右侧面板** → 选择 **Signing & Capabilities**

4. **配置签名**：
   - ✅ 勾选 **Automatically manage signing**
   - **Team**: 下拉选择朋友的 Apple ID
     - 如果没有，点击 **Add Account...**
     - 输入 Apple ID 和密码登录
   - **Bundle Identifier**: 应该已自动更新为刚才设置的

5. **检查 Capabilities**（应该自动配置）：
   - ✅ Background Modes
     - ✅ Acts as a BLE Central
     - ✅ Acts as a BLE Peripheral

### 步骤 5: 选择真机并运行

**在 Xcode 中**：

1. **顶部工具栏** → 点击设备选择器
2. **选择朋友的 iPhone**（不是模拟器）
3. 点击 **运行按钮** (▶️)

**或者使用命令行**：

```bash
# 清理并重新构建
flutter clean
flutter pub get

# 查看可用设备
flutter devices

# 在真机上运行
flutter run
```

---

## 📱 iPhone 信任开发者

首次运行时，需要在 iPhone 上信任开发者：

1. 打开 **设置** → **通用** → **VPN 与设备管理**
2. 找到朋友的 Apple ID 邮箱
3. 点击 **信任 "朋友的邮箱"**
4. 确认信任

---

## ⚠️ 常见问题排查

### 问题 1: "No signing certificate found"

**解决方法**：

1. Xcode → Settings (或 Preferences)
2. 选择 **Accounts** 标签
3. 选择朋友的 Apple ID
4. 点击 **Manage Certificates**
5. 点击左下角 **+** 号
6. 选择 **iOS Signing**
7. 等待证书生成
8. 关闭证书窗口，重新勾选 "Automatically manage signing"

### 问题 2: "Code signing is required for product type 'Application'"

**检查清单**：

- [ ] 是否已勾选 "Automatically manage signing"
- [ ] Team 是否已选择
- [ ] Bundle ID 是否正确

### 问题 3: Flutter 找不到设备

**解决方法**：

```bash
# 重启 Flutter 设备发现
flutter devices

# 如果还不行，重启 Xcode
killall Xcode
open ios/Runner.xcworkspace
```

### 问题 4: "User interaction is not allowed"

**原因**：需要解锁钥匙串

**解决方法**：
1. 打开 **钥匙串访问** (Keychain Access)
2. 右键点击 **login** 钥匙串
3. 选择 **解锁钥匙串**
4. 输入 Mac 登录密码

### 问题 5: 蓝牙无法使用

**检查**：

- [ ] 是否使用真机（模拟器不支持蓝牙）
- [ ] iPhone 蓝牙是否已开启
- [ ] 是否在 App 内授予了蓝牙权限
- [ ] 是否在 iPhone 设置中授予了定位权限

---

## 🎯 快速命令参考

```bash
# 进入项目目录
cd /path/to/bipupu/mobile

# 运行设置脚本
./setup_ios_temporary_build.sh

# 打开 Xcode
open ios/Runner.xcworkspace

# Flutter 常用命令
flutter clean                    # 清理构建
flutter pub get                 # 获取依赖
flutter devices                 # 查看设备
flutter run                     # 运行应用
flutter run -d <device_id>      # 指定设备运行
```

---

## 📞 远程协助提示

### 使用屏幕共享时

1. **让朋友共享屏幕**
   - macOS 自带：信息 App → 视频通话 → 共享屏幕
   - 或使用腾讯会议/钉钉等

2. **操作建议**
   - 让朋友坐在电脑前，你远程指导
   - 关键步骤（如输入密码）让朋友自己操作
   - 使用屏幕标注功能指示点击位置

3. **语音沟通**
   - 保持语音通话畅通
   - 每一步操作前说明意图

---

## ✅ 验证成功标志

运行成功后，应该看到：

1. ✅ Xcode 底部显示 "Runner.app installed on iPhone"
2. ✅ iPhone 上出现 BIPUPU 应用图标
3. ✅ 应用可以正常启动
4. ✅ 在应用内可以扫描蓝牙设备

---

## 🔄 7 天后过期处理

免费账户签名的应用 7 天后会无法打开：

**重新签名步骤**：

1. 连接 iPhone
2. 运行：
   ```bash
   flutter clean
   flutter run
   ```
3. 或在 Xcode 中重新点击运行

---

## 📝 Bundle ID 说明

Bundle ID 格式：`com.标识.bipupu`

**标识可以是**：
- 朋友的名字拼音（如 `com.zhangsan.bipupu`）
- 朋友的邮箱前缀（如 `com.john.bipupu`）
- 任意唯一字符串（如 `com.bipupu.test.2026`）

**注意**：
- 不能与 App Store 已有应用重复
- 使用小写字母和数字
- 用点号分隔

---

## 🔗 相关文档

- `IOS_BUILD_REPORT.md` - 完整检测报告
- `ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md` - 详细打包指南
- `setup_ios_temporary_build.sh` - 自动设置脚本

---

## 💡 提示

1. **首次配置可能需要 10-15 分钟**（下载证书、配置文件等）
2. **保持网络畅通**（需要连接 Apple 服务器）
3. **iPhone 保持解锁状态**（便于信任开发者）
4. **建议先测试简单功能**，再测试蓝牙等复杂功能
