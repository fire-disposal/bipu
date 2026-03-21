# iOS 临时账户打包配置指南

## 📋 前提条件

1. **Apple ID**：有效的 Apple ID（免费账户即可）
2. **Xcode**：已安装 Xcode 15.0+
3. **Flutter**：已安装 Flutter 3.10+

---

## 🔧 配置步骤

### 步骤 1：修改 Bundle ID

由于使用临时账户，需要修改唯一的 Bundle ID 避免冲突。

**方法 A：手动修改（推荐）**

编辑文件：`ios/Runner.xcodeproj/project.pbxproj`

找到以下行并修改：
```
PRODUCT_BUNDLE_IDENTIFIER = com.bipupu.user.flutterUser;
```

改为（使用你的 Apple ID 邮箱）：
```
PRODUCT_BUNDLE_IDENTIFIER = com.你的邮箱.bipupu;
```

例如：`com.firedisposal.bipupu` 或 `com.yourname.bipupu`

**方法 B：使用脚本自动修改**

```bash
cd mobile
# 替换为你的唯一标识
sed -i '' 's/com.bipupu.user.flutterUser/com.你的标识.bipupu/g' ios/Runner.xcodeproj/project.pbxproj
```

---

### 步骤 2：Xcode 自动签名配置

1. 打开项目：
   ```bash
   cd mobile
   open ios/Runner.xcworkspace
   ```

2. 在 Xcode 中：
   - 选择 **Runner** 项目
   - 选择 **Runner** Target
   - 进入 **Signing & Capabilities** 标签页

3. 配置签名：
   - ✅ 勾选 **Automatically manage signing**
   - **Team**: 选择你的 Apple ID（如果没有，点击 "Add Account..." 添加）
   - **Bundle Identifier**: 确认与步骤 1 修改的一致
   - **Signing Certificate**: 会自动配置为 "iOS Development"
   - **Provisioning Profile**: 会自动生成 "iOS Team Provisioning Profile"

4. 对 **RunnerTests** Target 重复上述步骤

---

### 步骤 3：配置 Capabilities

在 Xcode 的 **Signing & Capabilities** 标签页中，点击 **"+ Capability"** 添加：

#### 必须添加的：
- ✅ **Background Modes**
  - ✅ Acts as a BLE Peripheral
  - ✅ Acts as a BLE Central
  - ✅ Remote notifications

#### 可选添加的：
- ✅ **Push Notifications**（如需推送通知）

---

### 步骤 4：修改部署目标（可选）

如果需要在较旧 iOS 设备上测试：

编辑 `ios/Podfile`：
```ruby
platform :ios, '13.0'  # 确保与 AppFrameworkInfo.plist 一致
```

---

### 步骤 5：构建并运行

```bash
cd mobile

# 清理构建缓存
flutter clean

# 获取依赖
flutter pub get

# 在真机上运行（推荐）
flutter run

# 或在模拟器上运行（蓝牙功能不可用）
flutter run -d <simulator_id>
```

---

## ⚠️ 临时账户限制

| 功能 | 免费账户 | 付费账户 |
|------|---------|---------|
| 真机调试 | ✅ 7 天有效期 | ✅ 1 年 |
| App Store 发布 | ❌ | ✅ |
| TestFlight | ❌ | ✅ |
| Push Notifications | ⚠️ 仅限真机 | ✅ |
| iCloud | ❌ | ✅ |
| Apple Pay | ❌ | ✅ |

**注意**：免费账户签名的应用每 7 天需要重新签名。

---

## 🔍 常见问题排查

### 问题 1: "No signing certificate found"

**解决方案**：
1. Xcode → Settings → Accounts
2. 选择你的 Apple ID
3. 点击 "Manage Certificates"
4. 点击 "+" 添加 "iOS Signing" 证书
5. 重启 Xcode

### 问题 2: "Provisioning profile not found"

**解决方案**：
```bash
cd mobile/ios
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
# 重新打开 Xcode 并重新勾选 "Automatically manage signing"
```

### 问题 3: 蓝牙无法使用

**检查清单**：
- [ ] 真机运行（模拟器不支持蓝牙）
- [ ] 设备蓝牙已开启
- [ ] Info.plist 中 `UIBackgroundModes` 包含 `bluetooth-central`
- [ ] Runner.entitlements 文件存在
- [ ] Xcode Capabilities 中已添加 Background Modes

### 问题 4: Bundle ID 冲突

**错误信息**："An application with this identifier already exists"

**解决方案**：
修改 `ios/Runner.xcodeproj/project.pbxproj` 中的 Bundle ID 为更唯一的标识：
```
PRODUCT_BUNDLE_IDENTIFIER = com.你的邮箱前缀.bipupu;
```

---

## 📦 归档打包（可选）

如需生成 .ipa 文件：

1. 在 Xcode 中选择 **Product** → **Archive**
2. 等待归档完成
3. 在 Organizer 中点击 **Distribute App**
4. 选择 **Custom** → **Next**
5. 选择 **Development** → **Next**
6. 选择你的证书和配置文件 → **Next**
7. 选择 **Export** → 选择保存位置 → **Export**

---

## 📝 检查清单

打包前确认：

- [ ] Bundle ID 已修改为唯一标识
- [ ] Xcode 已登录 Apple ID
- [ ] 自动签名已启用
- [ ] Runner.entitlements 文件存在
- [ ] Info.plist 权限描述完整
- [ ] Background Modes 已配置
- [ ] 使用真机测试（蓝牙功能）
- [ ] 应用能在真机上成功启动

---

## 🔗 相关资源

- [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)
- [Apple 开发者免费计划](https://developer.apple.com/cn/programs/compare-features/)
- [Xcode 签名配置指南](https://help.apple.com/xcode/mac/current/#/dev60b67c7ed)
